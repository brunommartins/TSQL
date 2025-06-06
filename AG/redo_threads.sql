select *--db_name(database_id) as dbname, command, session_id 
from sys.dm_exec_requests
where command in('PARALLEL REDO HELP TASK', 'PARALLEL REDO TASK', 'DB STARTUP')
and database_id= db_id('dbname')

select db_name(database_id) as dbname, database_id, session_id, start_time, status, command, wait_type, wait_time, blocking_session_id, wait_resource
from sys.dm_exec_requests
where 1=1
and command in('PARALLEL REDO HELP TASK', 'PARALLEL REDO TASK', 'DB STARTUP')
and database_id= db_id('dbname')


select session_id, command, blocking_session_id, wait_time, wait_type, wait_resource   
from sys.dm_exec_requests where command = 'DB STARTUP'  

select recovery_lsn, truncation_lsn, last_hardened_lsn, last_received_lsn,   
   last_redone_lsn, last_redone_time  
from sys.dm_hadr_database_replica_states 

select * from sys.dm_hadr_ag_threads

select * from  sys.dm_hadr_db_threads


--Habilita o single thread
DBCC TRACEON (3459, -1);
GO

--aumeta o número de threads,se a VM tiver mais de 16CPU,  N CPu -16*100
--habilitar somente 1x 
DBCC TRACEON (3478, -1);
GO

--Desabilita o single thread, voltando para paralelismo de threads
DBCC TRACEOFF (3459, -1);
GO


dbcc tracestatus

select DB_NAME(database_id),
* from sys.dm_exec_requests
where command like '%redo%'
or command like '%hadr%'
order by database_id


CREATE EVENT SESSION [redo_wait_info] ON SERVER
ADD EVENT sqlos.wait_info(
ACTION(package0.event_sequence,
sqlos.scheduler_id,
sqlserver.database_id,
sqlserver.session_id)
WHERE ( [opcode]=(1)

     AND sqlserver.session_id = (157)

))
ADD TARGET package0.event_file(
SET filename=N'redo_wait_info')
WITH (MAX_MEMORY=4096 KB,
EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,
MAX_DISPATCH_LATENCY=30 SECONDS,
MAX_EVENT_SIZE=0 KB,
MEMORY_PARTITION_MODE=NONE,
TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO


ALTER EVENT SESSION [redo_wait_info] ON SERVER STATE=START
WAITFOR DELAY '00:00:30'
ALTER EVENT SESSION [redo_wait_info] ON SERVER STATE=STOP
