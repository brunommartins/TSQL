-- lista as queries lentas em tempo de execução com tempo maior que 5s
SELECT
    s.host_name,
    r.session_id,
    r.status,
    r.start_time,
    r.cpu_time,
    r.total_elapsed_time,
    r.logical_reads,
    r.writes,
    r.command,
    s.host_name,
    s.login_name,
    t.text AS sql_text
FROM
    sys.dm_exec_requests r
JOIN
    sys.dm_exec_sessions s ON r.session_id = s.session_id
CROSS APPLY
    sys.dm_exec_sql_text(r.sql_handle) t
WHERE
    r.status <> 'background'
    AND r.total_elapsed_time > 5000 -- milissegundos
ORDER BY
    r.total_elapsed_time DESC;


--lista bloqueios 
	SELECT
    r.session_id,
    r.status,
    r.blocking_session_id,
    r.wait_type,
    r.wait_time,
    r.wait_resource,
    r.command,
    r.cpu_time,
    r.total_elapsed_time,
    s.login_name,
    s.host_name,
    s.program_name,
    t.text AS sql_text
FROM sys.dm_exec_requests r
JOIN sys.dm_exec_sessions s ON r.session_id = s.session_id
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
WHERE r.blocking_session_id <> 0
ORDER BY r.blocking_session_id;




--lista queries antigas (recentes) que ainda estão no cache
SELECT TOP 10
    qs.total_elapsed_time / qs.execution_count AS avg_elapsed_time,
    qs.execution_count,
    qs.total_elapsed_time,
    qs.total_logical_reads,
    qs.total_worker_time,
    SUBSTRING(st.text, (qs.statement_start_offset/2) + 1,
              ((CASE qs.statement_end_offset
                  WHEN -1 THEN DATALENGTH(st.text)
                  ELSE qs.statement_end_offset END
               - qs.statement_start_offset)/2) + 1) AS query_text,
    st.dbid,
    st.objectid
FROM
    sys.dm_exec_query_stats qs
CROSS APPLY
    sys.dm_exec_sql_text(qs.sql_handle) AS st
ORDER BY
    avg_elapsed_time DESC;


