--Step 1 - 

-- Generate CREATE CREDENTIAL statements (you must manually provide the password)
SELECT 
    'CREATE CREDENTIAL [' + name + '] 
     WITH IDENTITY = N''' + credential_identity + ''', 
     SECRET = N''<PASSWORD_HERE>'';' AS CreateCredentialScript
FROM sys.credentials;

--Step 2 -
-- Export proxy accounts with associated credential names
SELECT 
    'EXEC msdb.dbo.sp_add_proxy 
        @proxy_name = N''' + p.name + ''', 
        @credential_name = N''' + c.name + ''', 
        @enabled = ' + CAST(p.enabled AS VARCHAR) + ';' AS CreateProxyScript
FROM msdb.dbo.sysproxies AS p
JOIN sys.credentials AS c ON p.credential_id = c.credential_id;


-- Export subsystems assigned to each proxy
SELECT 
    'EXEC msdb.dbo.sp_grant_proxy_to_subsystem 
        @proxy_name = N''' + p.name + ''', 
        @subsystem_name = N''' + 
        CASE s.subsystem_id
            WHEN 1 THEN 'ActiveScripting'
            WHEN 2 THEN 'CmdExec'
            WHEN 3 THEN 'PowerShell'
            WHEN 4 THEN 'SSIS'
            WHEN 6 THEN 'ReplicationSnapshot'
            WHEN 7 THEN 'ReplicationLogReader'
            WHEN 8 THEN 'ReplicationDistribution'
            WHEN 9 THEN 'ReplicationMerge'
            WHEN 10 THEN 'ReplicationQueueReader'
            WHEN 11 THEN 'AnalysisServicesCommand'
            WHEN 12 THEN 'AnalysisServicesQuery'
            WHEN 13 THEN 'SSAS'
            WHEN 14 THEN 'TransactSql'
            ELSE 'UNKNOWN'
        END + ''';'
FROM msdb.dbo.sysproxysubsystem AS s
JOIN msdb.dbo.sysproxies AS p ON s.proxy_id = p.proxy_id;



-- Export login permissions associated with each proxy
SELECT 
    'EXEC msdb.dbo.sp_grant_login_to_proxy 
        @proxy_name = N''' + p.name + ''', 
        @login_name = N''' + sp.name + ''';'
FROM msdb.dbo.sysproxylogin AS pl
JOIN msdb.dbo.sysproxies AS p ON pl.proxy_id = p.proxy_id
JOIN sys.server_principals AS sp ON pl.sid = sp.sid;

