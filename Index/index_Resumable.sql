--(Resumable Index Rebuild) no SQL Server

SELECT case when state_desc='RUNNING' and percent_complete>0
            then dateadd(ss, DATEDIFF(ss, start_time, getdate())*100/percent_complete, start_time)
            else null end previsao,
       state_desc, percent_complete, start_time, total_execution_time, page_count, sql_text
FROM sys.index_resumable_operations


SELECT 
    CASE 
        WHEN state_desc = 'RUNNING' AND percent_complete > 0
        THEN DATEADD(SECOND, 
                     (DATEDIFF(SECOND, start_time, GETDATE()) * 100 / percent_complete) 
                     - DATEDIFF(SECOND, start_time, GETDATE()), 
                     GETDATE()) 
        ELSE NULL 
    END AS previsao_termino,
    state_desc, 
    percent_complete, 
    start_time, 
    total_execution_time / 1000 AS total_exec_segundos,
    page_count, 
    sql_text
FROM sys.index_resumable_operations;
