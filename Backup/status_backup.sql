SELECT
er.session_id
,er.start_time
,er.status
,er.command
,er.percent_complete
,er.estimated_completion_time /60/1000 as estimate_completion_minutes
,DATEADD(n,(estimated_completion_time /60/1000),GETDATE()) as estimated_completion_time
,SUBSTRING(st.text, er.statement_start_offset / 2,
(CASE WHEN er.statement_end_offset = -1 THEN LEN(CONVERT(nvarchar(max), st.text)) * 2
ELSE er.statement_end_offset END - er.statement_start_offset) / 2) AS query_text
,es.login_name
,es.host_name
,es.program_name
,er.wait_type
,er.wait_time
,er.last_wait_type
,er.wait_resource
FROM sys.dm_exec_connections ec
LEFT OUTER JOIN sys.dm_exec_sessions es ON ec.session_id = es.session_id
LEFT OUTER JOIN sys.dm_exec_requests er ON ec.connection_id = er.connection_id
OUTER APPLY sys.dm_exec_sql_text(sql_handle) st
OUTER APPLY sys.dm_exec_query_plan(plan_handle) ph
WHERE er.command = 'BACKUP DATABASE' OR er.command = 'BACKUP LOG' OR er.command = 'RESTORE DATABASE' OR er.command = 'RESTORE LOG' OR er.command = 'RESTORE HEADERONLY'
ORDER BY es.program_name DESC;
