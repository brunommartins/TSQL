CREATE TABLE dbo.Log_RoutingListUpdates (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    ExecutionDate DATETIME DEFAULT GETDATE(),
    ExecutedOn SYSNAME,
    ScriptText NVARCHAR(MAX)
);
GO


CREATE OR ALTER PROCEDURE dbo.usp_UpdateRoutingList
AS
BEGIN
    SET NOCOUNT ON;

    -- Executar apenas se for a réplica primária
    IF NOT EXISTS (
        SELECT 1
        FROM sys.dm_hadr_availability_replica_states ars
        JOIN sys.availability_replicas ar ON ars.replica_id = ar.replica_id
        WHERE ars.role_desc = 'PRIMARY'
          AND ar.replica_server_name = @@SERVERNAME
    )
    BEGIN
        PRINT  @@SERVERNAME + ' - Este nó não é o primário. Nenhuma alteração foi feita.';
        RETURN;
    END

    DECLARE @sql NVARCHAR(MAX) = '';
	DECLARE @AGname varchar(50) = '' 


	select @AGname = name from sys.availability_groups

    IF OBJECT_ID('tempdb..#SyncedReplicas') IS NOT NULL DROP TABLE #SyncedReplicas;

    -- Lista das réplicas sincronizadas
    SELECT DISTINCT
        ar.replica_server_name
    INTO #SyncedReplicas
    FROM sys.dm_hadr_database_replica_states dbrs
    JOIN sys.availability_replicas ar ON ar.replica_id = dbrs.replica_id
    WHERE dbrs.synchronization_state = 2;

    -- Cursor para montar o routing list para cada réplica
    DECLARE @replica SYSNAME;
    DECLARE cur CURSOR FOR
        SELECT replica_server_name FROM #SyncedReplicas;

    OPEN cur
    FETCH NEXT FROM cur INTO @replica;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @group1 NVARCHAR(MAX) = '';
        DECLARE @group2 NVARCHAR(MAX) = '';
        DECLARE @linha NVARCHAR(MAX) = '';

        -- Lista com os outros (prioridade 1)
        SELECT @group1 = STRING_AGG(CHAR(39) + replica_server_name +  CHAR(39), ',')
        FROM #SyncedReplicas
        WHERE replica_server_name <> @replica;

        -- Prioridade 2: ele mesmo
        SET @group2 = CHAR(39) + @replica +  CHAR(39);

        SET @linha = 'USE [master]
ALTER AVAILABILITY GROUP ['+@AGname+']
MODIFY REPLICA ON N''' + @replica + ''' WITH
(
    PRIMARY_ROLE (READ_ONLY_ROUTING_LIST = 
        ((' + @group1 + '), (' + @group2 + '))
    )
);'

        SET @sql += @linha;

        FETCH NEXT FROM cur INTO @replica;
    END

    CLOSE cur;
    DEALLOCATE cur;

    DROP TABLE #SyncedReplicas;

    -- Executa os comandos montados
    print @sql
	EXEC sp_executesql @sql;

    -- Grava log
    INSERT INTO dbo.Log_RoutingListUpdates (ExecutedOn, ScriptText)
    VALUES (@@SERVERNAME, @sql);
END;



--select * from Log_RoutingListUpdates
