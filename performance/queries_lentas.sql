


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


