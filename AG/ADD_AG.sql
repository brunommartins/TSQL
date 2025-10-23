DECLARE @NEW_SERVER_NAME VARCHAR(32) = 'servername' /**** alterar aqui ****/
DECLARE @AZ1P_SERVER_1 VARCHAR(32) = @@SERVERNAME, @AZ1P_SERVER_2 VARCHAR(32)
;

select TOP(1) @AZ1P_SERVER_2 = replica_server_name 
from sys.availability_replicas 
where replica_server_name like 'az1p%'
and replica_server_name <> @@SERVERNAME
;


select 
'
IF(@@SERVERNAME LIKE ''xxx%'')
BEGIN
ALTER AVAILABILITY GROUP ['+name+']
ADD REPLICA ON N'''+@NEW_SERVER_NAME+''' WITH (ENDPOINT_URL = N''TCP://'+@NEW_SERVER_NAME+'.comain:5022''
, FAILOVER_MODE = MANUAL, AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT, BACKUP_PRIORITY = 50
, SECONDARY_ROLE(ALLOW_CONNECTIONS = ALL));
END' as t_sql_add_replica_server_1,
'IF(@@SERVERNAME LIKE ''AZ4P%'')
BEGIN
ALTER AVAILABILITY GROUP ['+name+'] JOIN;
END'
as t_sql_join_server_2
from sys.availability_groups 
order by name asc



select  
'
IF(@@SERVERNAME LIKE ''yyy%'')
BEGIN
ALTER DATABASE ['+db_name(drs.database_id)+'] SET HADR AVAILABILITY GROUP = ['+ag.name+'];
END' as t_sql_join_db_3
from sys.availability_groups ag  
inner join sys.dm_hadr_availability_group_states ags on ags.group_id = ag.group_id
inner join sys.dm_hadr_database_replica_states drs on drs.group_id = ag.group_id  
inner join sys.dm_hadr_availability_replica_cluster_states rcs on rcs.replica_id = drs.replica_id 
inner join sys.dm_hadr_availability_replica_states ars on ars.group_id = ag.group_id and drs.replica_id = ars.replica_id  
where rcs.replica_server_name = @@SERVERNAME
order by ag.name asc
;


select 
'
IF(@@SERVERNAME LIKE ''xxx%'')
BEGIN
ALTER AVAILABILITY GROUP ['+name+']
MODIFY REPLICA ON N'''+@NEW_SERVER_NAME+''' 
WITH (SECONDARY_ROLE(READ_ONLY_ROUTING_URL = N''TCP://'+@NEW_SERVER_NAME+'.domain:1433''));
END' as t_sql_add_read_only_routing_url_4
,
'
IF(@@SERVERNAME LIKE ''xxx%'')
BEGIN
ALTER AVAILABILITY GROUP ['+name+']
MODIFY REPLICA ON N'''+@AZ1P_SERVER_1+''' WITH (PRIMARY_ROLE(READ_ONLY_ROUTING_LIST = (N'''+@NEW_SERVER_NAME+''')));
ALTER AVAILABILITY GROUP ['+name+']
MODIFY REPLICA ON N'''+@AZ1P_SERVER_2+''' WITH (PRIMARY_ROLE(READ_ONLY_ROUTING_LIST = (N'''+@NEW_SERVER_NAME+''')));
END' as t_sql_modify_ro_readonly_5
from sys.availability_groups 
order by name asc
