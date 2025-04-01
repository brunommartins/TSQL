select DB_ID('dbname')

select * from sys.dm_db_log_info(42)

select file_id, vlf_active, COUNT(*)
from sys.dm_db_log_info(42)
 group by file_id, vlf_active
