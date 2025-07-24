USE [master]
GO

/****** Object:  DdlTrigger [PasswordPolicyCheck]    Script Date: 7/24/2025 9:38:14 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [PasswordPolicyCheck] ON ALL SERVER
FOR CREATE_LOGIN, ALTER_LOGIN
AS
BEGIN
SET QUOTED_IDENTIFIER OFF
 DECLARE @SQLText Varchar(2000),@LoginName Varchar(100)
 SELECT @SQLText=EVENTDATA().value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]','nvarchar(max)')
 SELECT @LoginName=EVENTDATA().value('(/EVENT_INSTANCE/ObjectName)[1]','nvarchar(max)')
 IF CHARINDEX('CHECK_POLICY=OFF',@SQLText) >0
 BEGIN
	RAISERROR('password policy must be enabled',10,1);
	ROLLBACK
 END
 ELSE IF EXISTS (SELECT 1 FROM sys.sql_logins WHERE name=@LoginName AND  is_policy_checked=0)
 BEGIN
  RAISERROR('password policy must be enabled',10,1);
	ROLLBACK
 END
END

GO

ENABLE TRIGGER [PasswordPolicyCheck] ON ALL SERVER
GO


