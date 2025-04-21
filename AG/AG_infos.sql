SELECT 
    ag.name AS AvailabilityGroupName,
    ar.replica_server_name AS ReplicaServerName,
    ars.role_desc AS RoleDescription
FROM sys.availability_groups ag
JOIN sys.availability_replicas ar 
    ON ag.group_id = ar.group_id
JOIN sys.dm_hadr_availability_replica_states ars
    ON ar.replica_id = ars.replica_id
.



SELECT 
    ar.replica_server_name AS ReplicaName,
    ars.role_desc AS Role,
    ar.availability_mode_desc AS AvailabilityMode,
    ar.failover_mode_desc AS FailoverMode,
    ar.seeding_mode_desc AS SeedingMode,
    drs.synchronization_state_desc AS SynchronizationState
FROM sys.availability_groups ag
JOIN sys.availability_replicas ar ON ag.group_id = ar.group_id
JOIN sys.dm_hadr_availability_replica_states ars ON ar.replica_id = ars.replica_id
JOIN sys.dm_hadr_database_replica_states drs ON ar.replica_id = drs.replica_id
    AND drs.database_id = DB_ID() -- pega o estado apenas do banco atual
WHERE ag.name = 'dbnmae'
GROUP BY 
    ar.replica_server_name,
    ars.role_desc,
    ar.availability_mode_desc,
    ar.failover_mode_desc,
    ar.seeding_mode_desc,
    drs.synchronization_state_desc
ORDER BY Role DESC;
