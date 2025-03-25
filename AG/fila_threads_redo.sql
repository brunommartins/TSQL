--rodar no node secundário

select db_name(database_id) as dbname, count(*)
from sys.dm_exec_requests
where 1=1
and command in('PARALLEL REDO HELP TASK', 'PARALLEL REDO TASK', 'DB STARTUP')
--and database_id= db_id('dbname')
group by  db_name(database_id)

