SELECT 
    ag.name AS AG_Name,
    db.name AS Database_Name,
    ar.replica_server_name,
    drs.is_commit_participant,
    drs.log_send_queue_size,
    drs.redo_queue_size,
    drs.redo_rate,
    drs.log_send_rate,
    drs.last_commit_time,
    drs.synchronization_state_desc,
    ars.synchronization_health_desc,
    ars.connected_state_desc
FROM 
    sys.dm_hadr_database_replica_states AS drs
JOIN 
    sys.availability_groups AS ag ON drs.group_id = ag.group_id
JOIN 
    sys.availability_replicas AS ar ON drs.replica_id = ar.replica_id AND drs.group_id = ar.group_id
JOIN 
    sys.dm_hadr_availability_replica_states AS ars 
        ON ar.replica_id = ars.replica_id AND ar.group_id = ars.group_id
JOIN 
    sys.availability_databases_cluster AS adc 
        ON drs.group_id = adc.group_id AND drs.group_database_id = adc.group_database_id
JOIN 
    sys.databases AS db ON adc.database_name = db.name
WHERE 
 1=1
  --  ag.name = 'AGNAME'
	--and  db.name = 'DB'
ORDER BY 
    db.name, is_commit_participant DESC, redo_queue_size DESC;
