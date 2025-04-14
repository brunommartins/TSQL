SELECT 
    ag.name AS [AG Name],
    ar.replica_server_name AS [Replica Name],
    ars.role_desc AS [Current Role],
    ar.availability_mode_desc AS [Availability Mode],
    ar.failover_mode_desc AS [Failover Mode],
    ars.connected_state_desc AS [Connected State],
    ars.synchronization_health_desc AS [Replica Health],
    db.name AS [Database],
    drs.synchronization_state_desc AS [DB Sync State],
    drs.synchronization_health_desc AS [DB Health],
    drs.redo_queue_size AS [Redo Queue Size],
    drs.log_send_queue_size AS [Log Send Queue Size],
    drs.last_commit_time AS [Last Commit Time]
FROM 
    sys.availability_groups ag
JOIN 
    sys.availability_replicas ar ON ag.group_id = ar.group_id
JOIN 
    sys.dm_hadr_availability_replica_states ars ON ar.replica_id = ars.replica_id
JOIN 
    sys.dm_hadr_database_replica_states drs ON ar.replica_id = drs.replica_id
JOIN 
    sys.databases db ON drs.database_id = db.database_id
ORDER BY 
    [AG Name], [Replica Name], [Database];
