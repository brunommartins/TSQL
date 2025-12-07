select top(100) *--start_lsn, tran_begin_time, tran_end_time 
from [cdc].[lsn_time_mapping] 
order by tran_begin_time desc;



SELECT 
    MAX(tran_end_time) AS Ultima_tran_CDC,
    GETDATE()          AS Agora,
    DATEDIFF(MINUTE, MAX(tran_end_time), GETDATE()) AS Atraso_Minutos
FROM cdc.lsn_time_mapping;


EXEC sys.sp_cdc_help_jobs-- @job_type = N'capture';



select name,type,type_desc,is_tracked_by_cdc
from sys.tables
where is_tracked_by_cdc = 1 
