DECLARE @tsql_text_or_procedure_name NVARCHAR(255)= 'select%ENTRY'

SELECT
OBJECT_NAME(Q.object_id) AS [procedure_name]
,Q.query_id
,P.plan_id
,I.start_time AT TIME ZONE 'Tocantins Standard Time' AS start_time
,I.end_time AT TIME ZONE 'Tocantins Standard Time' AS end_time
,T.query_sql_text
,ROW_NUMBER() OVER (PARTITION BY Q.query_id, P.plan_id, I.start_time ORDER BY WS.avg_query_wait_time_ms DESC)
,WS.wait_category_desc
,WS.avg_query_wait_time_ms
,WS.min_query_wait_time_ms
,WS.max_query_wait_time_ms
,WS.execution_type_desc
FROM sys.query_store_query Q
INNER JOIN sys.query_store_query_text T
ON Q.query_text_id = T.query_text_id
INNER JOIN sys.query_store_plan P
ON Q.query_id = P.query_id
INNER JOIN sys.query_store_runtime_stats S
ON P.plan_id = S.plan_id
INNER JOIN sys.query_store_runtime_stats_interval I
ON S.runtime_stats_interval_id = I.runtime_stats_interval_id
INNER JOIN sys.query_store_wait_stats WS
ON WS.plan_id = S.plan_id
AND WS.runtime_stats_interval_id = S.runtime_stats_interval_id
WHERE (T.query_sql_text LIKE '%' + @tsql_text_or_procedure_name + '%'
OR OBJECT_NAME(Q.object_id) = @tsql_text_or_procedure_name)
--AND I.start_time > DATEADD(dd,-27, GETDATE()) --UTC
 and I.start_time between '2021-03-18 22:00:00.0000000 -03:00' and '2021-03-18 23:35:00.0000000 -03:00'
AND WS.execution_type_desc <> 'Aborted'
ORDER BY I.start_time DESC
