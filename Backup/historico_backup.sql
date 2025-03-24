SELECT distinct  
CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server, 
 --ROW_NUMBER() OVER (PARTITION BY bst.database_name ORDER BY bst.database_name),
bst.backup_set_id, 
bst.database_name, 
bst.type, 
 CASE bst.type
        WHEN 'D' THEN 'Full'
        WHEN 'L' THEN 'Log'
        WHEN 'I' THEN 'Diferencial'
        WHEN 'F' THEN 'File ou Filegroup'
        WHEN 'G' THEN 'Diferencial Arquivo'
        WHEN 'P' THEN 'Parcial'
        WHEN 'Q' THEN 'Diferencial Parcial'
    END AS 'Tipo do Backup',
	
    DATENAME(dw,CONVERT(date,backup_start_date)) as [days],
bst.backup_start_date, 
bst.backup_finish_date, 
bst.backup_size, 
convert(decimal(18,3),backup_size/1024/1024/1024) as SizeinGB,
--bst.name AS backupset_name
convert(varchar(10), (DATEDIFF(SECOND,backup_start_date,backup_finish_date) /86400)) + 'd:' +
convert(varchar(10), ((DATEDIFF(SECOND,backup_start_date,backup_finish_date) %86400)/3600)) + 'h:'+
convert(varchar(10), (((DATEDIFF(SECOND,backup_start_date,backup_finish_date) %86400)%3600)/60)) + 'min:'+
convert(varchar(10), (((DATEDIFF(SECOND,backup_start_date,backup_finish_date) %86400)%3600)%60)) +'seg 'as 'DD:HH:MM:SS',
bst.description,
bmf.logical_device_name,
--bmf.physical_device_name,
bst.recovery_model,
bst.is_copy_only,
bst.is_snapshot
FROM msdb.dbo.backupmediafamily bmf
INNER JOIN msdb.dbo.backupset as bst ON bmf.media_set_id = bst.media_set_id 
WHERE (CONVERT(datetime, bst.backup_start_date, 102) >= '2025-03-22 00:00')  -- verificar a data que deseja iniciar a pesquisa
 -- and db_id(bst.database_name) > 4
and database_name = 'dbname' -- alterar o nome da base de dados
--and type <> 'L' -- exclui backups de log
ORDER BY 
bst.backup_start_date
desc
