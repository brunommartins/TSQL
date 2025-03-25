--para está query é importante lembrar que o Query Store precisa estar habilitado.

DECLARE @tsql_text_or_procedure_name NVARCHAR(255)= '%XXXXXX%'  --colocar o nome da view, tabela, procedure que deseja procurar
  
SELECT 
       OBJECT_NAME(Q.object_id) AS [procedure_name]
          ,Q.query_id
          ,P.plan_id
          ,I.start_time AT TIME ZONE 'Tocantins Standard Time' AS start_time
       ,I.end_time   AT TIME ZONE 'Tocantins Standard Time' AS end_time       
       ,T.query_sql_text
       ,S.count_executions
	   ,S.count_executions/(DATEDIFF(SECOND,I.start_time,I.end_time)) as 'execution/seconds'
          ,S.avg_duration / 1000 AS avg_duration_ms
          ,S.last_duration / 1000 AS last_duration_ms
          ,S.[min_duration] / 1000 AS [min_duration_ms]
          ,S.[max_duration] / 1000 AS [max_duration_ms]
          ,S.avg_cpu_time / 1000 AS [avg_cpu_ms]
          ,CONVERT(DECIMAL(10,2), S.avg_cpu_time / S.avg_duration * 100) AS cpu_perc
          ,S.avg_logical_io_reads
          ,S.execution_type_desc
		  ,S.avg_rowcount
FROM sys.query_store_query Q
INNER JOIN sys.query_store_query_text T ON Q.query_text_id = T.query_text_id
INNER JOIN sys.query_store_plan P ON Q.query_id = P.query_id
INNER JOIN sys.query_store_runtime_stats S ON P.plan_id = S.plan_id
INNER JOIN sys.query_store_runtime_stats_interval I ON S.runtime_stats_interval_id = I.runtime_stats_interval_id
 WHERE (T.query_sql_text LIKE  @tsql_text_or_procedure_name 
 OR OBJECT_NAME(Q.object_id) like @tsql_text_or_procedure_name)
--where Q.query_id = 16838
 and T.query_sql_text not like '%STATISTICS%'
-- and T.query_sql_text not like '%INSERT%'
 and I.start_time > '2025-02-07 06:00:00.0000000 -03:00' --and '2021-03-19 23:35:00.0000000 -03:00'
 --and S.avg_duration / 1000 > 4000
 --where Q.query_hash = 0xA5948BFE11369534
  -- and S.avg_rowcount > 100
ORDER BY I.start_time DESC

