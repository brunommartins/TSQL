
SELECT 
    s.host_name,
    s.program_name,
    s.login_name,
    DB_NAME(r.database_id) AS database_name,
    s.session_id,
    r.status,
    r.command,
    r.cpu_time,
    r.total_elapsed_time,
    r.wait_type,
    r.wait_time,
    r.blocking_session_id,
    r.reads,
    r.writes,
    r.logical_reads,
    r.start_time,
    --DATEDIFF(SECOND, r.start_time, GETDATE()) AS time_run_sec,
	CONVERT(varchar(8), DATEADD(SECOND, DATEDIFF(SECOND, r.start_time, GETDATE()), 0), 108) AS time_running,
 
    COUNT(*) OVER (PARTITION BY s.host_name) AS session_count_per_host,
    SUBSTRING(st.text, r.statement_start_offset / 2 + 1, 
        (CASE 
            WHEN r.statement_end_offset = -1 
            THEN LEN(CONVERT(nvarchar(max), st.text)) * 2 
            ELSE r.statement_end_offset 
         END - r.statement_start_offset) / 2 + 1) AS sql_text,
		 st.text AS full_query_text
FROM 
    sys.dm_exec_requests AS r
JOIN 
    sys.dm_exec_sessions AS s ON r.session_id = s.session_id
CROSS APPLY 
    sys.dm_exec_sql_text(r.sql_handle) AS st
WHERE 
    s.is_user_process = 1
     AND DB_NAME(r.database_id) = 'Agiplan'
   -- AND s.session_id = 52
ORDER BY 
    s.session_id asc,  r.blocking_session_id


    exec master.dbo.sp_WhoIsActive  @sort_order= '[session_id] ASC', @get_plans =1, @get_locks = 1



    SELECT 
    waiting_tasks_count,
    wait_time_ms
FROM sys.dm_os_wait_stats
WHERE wait_type = 'THREADPOOL';


SELECT 
    max_workers_count
FROM sys.dm_os_sys_info;


SELECT
    SUM(active_workers_count) AS active_workers,
    SUM(work_queue_count)     AS work_queue_tasks,
    SUM(runnable_tasks_count) AS runnable_tasks
FROM sys.dm_os_schedulers
WHERE status = 'VISIBLE ONLINE';



;WITH s AS (
    SELECT
        SUM(active_workers_count) AS active_workers,
        SUM(work_queue_count)     AS work_queue_tasks
    FROM sys.dm_os_schedulers
    WHERE status = 'VISIBLE ONLINE'
),
i AS (
    SELECT max_workers_count
    FROM sys.dm_os_sys_info
)
SELECT
    i.max_workers_count,
    s.active_workers,
    s.work_queue_tasks,
    CAST(100.0 * s.active_workers / NULLIF(i.max_workers_count,0) AS decimal(6,2)) AS pct_workers_in_use
FROM s
CROSS JOIN i;
