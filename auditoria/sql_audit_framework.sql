USE [master]
GO

/*
 No disco D criar a pasta 
   G:\MSSQL\SQLAudits
*/
DECLARE @exists INT;

CREATE TABLE #dircheck (output NVARCHAR(500));

INSERT INTO #dircheck
EXEC xp_cmdshell 'IF EXIST "G:\MSSQL\SQLAudits" (echo 1) ELSE (echo 0)';

SELECT TOP 1 @exists = TRY_CAST(output AS INT) FROM #dircheck WHERE output IN ('0','1');

DROP TABLE #dircheck;

IF @exists = 0
BEGIN
    EXEC xp_create_subdir 'G:\MSSQL\SQLAudits\';
    PRINT 'Diretório criado';
END
ELSE
BEGIN
    PRINT 'Diretório já existe';
END

IF NOT EXISTS (SELECT 1 FROM sys.server_audits WHERE name = 'LogonAttempts-Audit')
BEGIN
    CREATE SERVER AUDIT [LogonAttempts-Audit]
    TO FILE (
        FILEPATH = N'G:\MSSQL\SQLAudits\',
        MAXSIZE = 512 MB,
        MAX_ROLLOVER_FILES = 10,
        RESERVE_DISK_SPACE = OFF
    ) WITH (QUEUE_DELAY = 1000, ON_FAILURE = CONTINUE);
END
ALTER SERVER AUDIT [LogonAttempts-Audit] WITH (STATE = ON);
GO

IF NOT EXISTS (SELECT 1 FROM sys.server_audits WHERE name = 'Default_SQLAudit')
BEGIN
    CREATE SERVER AUDIT [Default_SQLAudit]
    TO FILE (
        FILEPATH = N'G:\MSSQL\SQLAudits\',
        MAXSIZE = 512 MB,
        MAX_ROLLOVER_FILES = 10,
        RESERVE_DISK_SPACE = OFF
    ) WITH (QUEUE_DELAY = 1000, ON_FAILURE = CONTINUE);
END
ALTER SERVER AUDIT [Default_SQLAudit] WITH (STATE = ON);
GO

IF NOT EXISTS (SELECT 1 FROM sys.server_audits WHERE name = 'cmdshell')
BEGIN
    CREATE SERVER AUDIT [cmdshell]
    TO FILE (
        FILEPATH = N'G:\MSSQL\SQLAudits\',
        MAXSIZE = 0 MB,
        MAX_ROLLOVER_FILES = 2147483647,
        RESERVE_DISK_SPACE = OFF
    ) WITH (QUEUE_DELAY = 1000, ON_FAILURE = CONTINUE);
END
ALTER SERVER AUDIT [cmdshell] WITH (STATE = ON);
GO

IF NOT EXISTS (SELECT 1 FROM sys.server_audit_specifications WHERE name = 'Default-ServerAuditSpecification')
BEGIN
    CREATE SERVER AUDIT SPECIFICATION [Default-ServerAuditSpecification]
    FOR SERVER AUDIT [Default_SQLAudit]
    ADD (DATABASE_ROLE_MEMBER_CHANGE_GROUP),
    ADD (SERVER_ROLE_MEMBER_CHANGE_GROUP),
    ADD (AUDIT_CHANGE_GROUP),
    ADD (DATABASE_PERMISSION_CHANGE_GROUP),
    ADD (DATABASE_OBJECT_PERMISSION_CHANGE_GROUP),
    ADD (SCHEMA_OBJECT_PERMISSION_CHANGE_GROUP),
    ADD (SERVER_OBJECT_PERMISSION_CHANGE_GROUP),
    ADD (SERVER_PERMISSION_CHANGE_GROUP),
    ADD (DATABASE_CHANGE_GROUP),
    ADD (DATABASE_OBJECT_CHANGE_GROUP),
    ADD (DATABASE_PRINCIPAL_CHANGE_GROUP),
    ADD (SCHEMA_OBJECT_CHANGE_GROUP),
    ADD (SERVER_OBJECT_CHANGE_GROUP),
    ADD (SERVER_PRINCIPAL_CHANGE_GROUP),
    ADD (APPLICATION_ROLE_CHANGE_PASSWORD_GROUP),
    ADD (LOGIN_CHANGE_PASSWORD_GROUP),
    ADD (SERVER_STATE_CHANGE_GROUP),
    ADD (USER_CHANGE_PASSWORD_GROUP)
    WITH (STATE = ON);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.server_audit_specifications WHERE name = 'LogonAttempts-AuditSpecification')
BEGIN
    CREATE SERVER AUDIT SPECIFICATION [LogonAttempts-AuditSpecification]
    FOR SERVER AUDIT [LogonAttempts-Audit]
    ADD (FAILED_LOGIN_GROUP),
    ADD (SUCCESSFUL_LOGIN_GROUP)
    WITH (STATE = ON);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.server_audit_specifications WHERE name = 'Audit-cmdshell')
BEGIN
    CREATE SERVER AUDIT SPECIFICATION [Audit-cmdshell]
    FOR SERVER AUDIT [cmdshell]
    ADD (SCHEMA_OBJECT_ACCESS_GROUP)
    WITH (STATE = ON);
END
GO

USE [DB_DBA];
GO

IF OBJECT_ID('dbo.tblSQLAuditCollectionStatus', 'U') IS NULL
BEGIN
	CREATE TABLE [dbo].[tblSQLAuditCollectionStatus](
		[LastCollectionStatus] [varchar](25) NULL,
		[LastCollectionStartTime] [datetime] NULL,
		[LastCollectionEndTime] [datetime] NULL,
		[LastCollectionAttempts] [tinyint] NULL,
		[LastSuccessfulCollection] [datetime] NULL,
		[LastSuccessfulRecordsLogged] [int] NULL,
		[Error] [varchar](4000) NULL,
		[RecordTimeStamp] [datetime] NULL
	) ON [PRIMARY]
END

IF OBJECT_ID('dbo.tblSQLAuditLogs', 'U') IS NULL
BEGIN
	   CREATE TABLE [dbo].[tblSQLAuditLogs](
		[server_instance_name] [sysname] NOT NULL,
		[action_id] [varchar](4) NULL,
		[session_id] [smallint] NULL,
		[server_principal_name] [sysname] NOT NULL,
		[session_server_principal_name] [sysname] NOT NULL,
		[database_principal_name] [sysname] NOT NULL,
		[database_name] [sysname] NOT NULL,
		[schema_name] [sysname] NOT NULL,
		[class_type] [varchar](2) NULL,
		[object_id] [int] NULL,
		[object_name] [sysname] NULL,
		[statement] [varchar](4000) NULL,
		[sequence_number] [smallint] NULL,
		[succeeded] [bit] NULL,
		[event_time_GMT] [datetime2](7) NULL,
		[file_name] [varchar](260) NULL,
		[LogTimestamp] [datetime] NULL
	) ON [PRIMARY]
END

IF NOT EXISTS (SELECT 1 FROM dbo.tblSQLAuditCollectionStatus)
BEGIN
    INSERT INTO dbo.tblSQLAuditCollectionStatus (LastCollectionStatus, LastSuccessfulCollection)
    VALUES ('Successful', '2023-01-01 00:01:00');
END
GO


/*
update [dbo].[tblSQLAuditCollectionStatus]
 set LastSuccessfulCollection = '2023-01-01 00:01:00'
*/



/****** Object:  StoredProcedure [dbo].[usp_SQLAudit_CollectAudits]    Script Date: 11/22/2023 10:40:01 AM ******/

CREATE OR ALTER PROCEDURE [dbo].[usp_SQLAudit_CollectAudits]
--@DateToFetch_GMT DateTime
AS
--Disable Row Counting
SET NOCOUNT ON

DECLARE @ServerName varchar(50);
DECLARE @AuditLogPath varchar(300);

DECLARE @AuditFile varchar(350);
DECLARE @strDateToFetch_GMT varchar(25);
--DECLARE @UtcOffset smallint;
DECLARE @myStmt varchar(2000);

DECLARE @StartTime DateTime;
DECLARE @EndTime DateTime;

DECLARE @RetriesLeft tinyint;
DECLARE @Attempts tinyint;
DECLARE @LastTryError varchar(4000);
DECLARE @RC int

---- ***************************************************************************
--Setting Variables

SELECT @strDateToFetch_GMT = CONVERT(varchar(25), DATEADD(HOUR, DATEDIFF(HOUR, GETDATE(), GETUTCDATE()), ISNULL(LastSuccessfulCollection, GETDATE()-1)), 126)  FROM [dbo].[tblSQLAuditCollectionStatus] WHERE LastCollectionStatus <> 'Running'

IF (@strDateToFetch_GMT IS NOT NULL)
BEGIN
	SELECT @ServerName = @@SERVERNAME
	SELECT @AuditLogPath = log_file_path from sys.server_file_audits WHERE name like 'Default_SQLAudit%'
	SET @AuditFile = @AuditLogPath + '\Default_SQLAudit' /*+ REPLACE(@ServerName, '\', '_') */+ '_*'

	SET @RetriesLeft = 5
	SET @Attempts = 0

	SET @myStmt = 'INSERT INTO [dbo].[tblSQLAuditLogs] '
				+ 'SELECT server_instance_name '
				+ ', action_id '
				+ ', session_id '
				+ ', server_principal_name '
				+ ', session_server_principal_name '
				+ ', database_principal_name '
				+ ', database_name '
				+ ', schema_name '
				+ ', class_type '
				+ ', object_id '
				+ ', object_name '
				+ ', statement '
				+ ', sequence_number '
				+ ', succeeded '
				+ ', event_time ' -- GMT time
				+ ', file_name '
				+ ', GETDATE() '
				+ 'FROM sys.fn_get_audit_file(''' + @AuditFile + ''',DEFAULT, DEFAULT) '
				+ 'WHERE event_time >= ''' + @strDateToFetch_GMT + ''''


	-- ***************************************************************************
	SET @StartTime = GetDate();

	WHILE (@RetriesLeft > 0)
	BEGIN

		BEGIN TRY

			SET @Attempts = @Attempts +1

			UPDATE [dbo].[tblSQLAuditCollectionStatus]
			   SET [LastCollectionStatus] = 'Running'
				   ,[LastCollectionStartTime] = @StartTime
				   ,[LastCollectionEndTime] = NULL
				   ,[LastCollectionAttempts] = @Attempts
				   --,[LastSuccessfulCollection]
				   --,[LastSuccessfulRecordsLogged]
				   ,[Error] = NULL
				   ,[RecordTimeStamp] = GetDate()

				EXECUTE (@myStmt);
				SET @RC = @@ROWCOUNT
		

			BREAK;
		END TRY
		BEGIN CATCH
			SET @LastTryError = ERROR_MESSAGE()		
			set @RetriesLeft = @RetriesLeft -1
			WAITFOR DELAY '00:00:10'
		END CATCH

	END

	SET @EndTime = GetDate();

	IF (@RetriesLeft = 0)
	BEGIN

		UPDATE [dbo].[tblSQLAuditCollectionStatus]
		   SET [LastCollectionStatus] = 'Error'
			   ,[LastCollectionStartTime] = @StartTime
			   ,[LastCollectionEndTime] = @EndTime
			   ,[LastCollectionAttempts] = @Attempts
			   --,[LastSuccessfulCollection]
			   --,[LastSuccessfulRecordsLogged]
			   ,[Error] = @LastTryError
			   ,[RecordTimeStamp] = GetDate()
	END
	ELSE
	BEGIN
		UPDATE [dbo].[tblSQLAuditCollectionStatus]
			SET [LastCollectionStatus] = 'Successful'
				,[LastCollectionStartTime] = @StartTime
				,[LastCollectionEndTime] = @EndTime
				,[LastCollectionAttempts] = @Attempts
				,[LastSuccessfulCollection] = @StartTime
				,[LastSuccessfulRecordsLogged] = @RC
				,[Error] = NULL
				,[RecordTimeStamp] = GetDate()
	END

END
ELSE
BEGIN
	PRINT 'Collection is already running'
END
GO


/****** Object:  StoredProcedure [dbo].[usp_SQLAudit_PurgeAudits]    Script Date: 11/22/2023 10:40:12 AM ******/


CREATE or ALTER PROCEDURE [dbo].[usp_SQLAudit_PurgeAudits]

AS
--Disable Row Counting
SET NOCOUNT ON

DECLARE @xdate AS DateTime;

SET @xdate = (SELECT DATEADD(dd, -500, GETUTCDATE()))

WHILE EXISTS (select TOP 1 1
				FROM [dbo].[tblSQLAuditLogs] 
				WHERE [event_time_GMT] < @xdate 
			)
BEGIN

	BEGIN Transaction
		
		DELETE TOP (10000)
		FROM [dbo].[tblSQLAuditLogs] 
		WHERE [event_time_GMT] < @xdate 
		
	COMMIT

END

GO


IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = 'SQLAudit_CollectAuditLogs')
BEGIN
    PRINT 'Job SQLAudit_CollectAuditLogs já existe. Nenhuma ação executada.';
    RETURN;
END


USE [msdb]
GO

declare @user nvarchar(150)

select @user =service_account from sys.dm_server_services where servicename like '%SQL Server%'

/****** Object:  Job [SQLAudit_CollectAuditLogs]    Script Date: 11/22/2023 10:39:31 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Data Collector]    Script Date: 11/22/2023 10:39:31 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Data Collector' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Data Collector'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'SQLAudit_CollectAuditLogs', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'This job is to collect and purge SQL Audits.', 
		@category_name=N'Data Collector', 
		@owner_login_name=@user,  --colocar o usuário da instância
		--@notify_email_operator_name=N'DBA',
		@job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [CollectAuditLogs]    Script Date: 11/22/2023 10:39:32 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'CollectAuditLogs', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXECUTE [dbo].[usp_SQLAudit_CollectAudits]', 
		@database_name=N'DB_DBA', 
		@flags=12
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [PurgeAuditLogs]    Script Date: 11/22/2023 10:39:32 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'PurgeAuditLogs', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXECUTE [dbo].[usp_SQLAudit_PurgeAudits]', 
		@database_name=N'DB_DBA', 
		@flags=12
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'SQLAudit_CollectAuditLogsSchedule', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=4, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20160810, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO




--Get the path for your audit files
declare @log_dir nvarchar(260);
set @log_dir = 
(select log_file_path+'D*.sqlaudit'
from sys.server_file_audits
where name = 'Default_SQLAudit');
--LogonAttempts-Audit
--Default_SQLAudit
--Read all the audit data you are interested in
SELECT * 
FROM sys.fn_get_audit_file(@log_dir, default, default)
--You can use a filter if requred
--where statement like '%{MyStatement}%'
--Show the most recent records first
order by event_time desc;
