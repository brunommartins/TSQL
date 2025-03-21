#lista a preferencia de backup do AG
#https://learn.microsoft.com/en-us/sql/t-sql/statements/alter-availability-group-transact-sql?view=sql-server-ver16
  
SELECT 
    ag.name AS AGName, 
    ag.automated_backup_preference_desc AS BackupPreference
FROM sys.availability_groups ag
WHERE ag.name = 'AGNAME';




#lista todas os nodes do AG e as preferências de backup
  
SELECT 
    ar.replica_server_name AS [Server Instance], 
    ar.backup_priority AS [Backup Priority], 
    CASE 
        WHEN ag.automated_backup_preference = 3 THEN 'Any Replica'
        WHEN ag.automated_backup_preference = 2 THEN 'Secondary Only'
        WHEN ag.automated_backup_preference = 1 THEN 'Prefer Secondary'
        WHEN ag.automated_backup_preference = 0 THEN 'Primary'
        ELSE 'Unknown'
    END AS [Backup Preference],
    CASE 
        WHEN ar.backup_priority = 0 THEN 'Yes'
        ELSE 'No'
    END AS [Exclude Replica]
FROM sys.availability_replicas ar
JOIN sys.availability_groups ag 
    ON ar.group_id = ag.group_id
ORDER BY ar.backup_priority DESC;



#altere o modo SQLCMD, coloque o nome da instancia, se tiver mais nodes, adicione mais linhas, desta forma você vai ver qual servidor está sendo escolhido pelo sql server para realizar o backup 

:connect SERVER\Inst01

SELECT 
@@SERVERNAME SQLName,    ag.name , failover_mode_desc, seeding_mode_desc,ar.replica_server_name,     ar.backup_priority,      ar.availability_mode_desc,    ars.role_desc,     ars.synchronization_health_desc,    [master].sys.fn_hadr_backup_is_preferred_replica('DBPIDICPRO') AS IsPreferredBackupReplica
FROM sys.availability_replicas ar
JOIN sys.dm_hadr_availability_replica_states ars     ON ar.replica_id = ars.replica_id
join sys.availability_groups ag on ar.group_id = ag.group_id
WHERE ars.is_local = 1;
go 
:connect SERVER\Inst02

SELECT 
@@SERVERNAME SQLName,    ag.name , failover_mode_desc, seeding_mode_desc,ar.replica_server_name,     ar.backup_priority,      ar.availability_mode_desc,    ars.role_desc,     ars.synchronization_health_desc,    [master].sys.fn_hadr_backup_is_preferred_replica('DBPIDICPRO') AS IsPreferredBackupReplica
FROM sys.availability_replicas ar
JOIN sys.dm_hadr_availability_replica_states ars     ON ar.replica_id = ars.replica_id
join sys.availability_groups ag on ar.group_id = ag.group_id
WHERE ars.is_local = 1;
go 
