
SELECT 
    max_workers_count,
    scheduler_count,
    cpu_count,
    hyperthread_ratio
FROM sys.dm_os_sys_info;

SELECT 
    GETDATE() AS CurrentDate,
    osi.max_workers_count AS TotalThreads,
    SUM(sch.active_workers_count) AS ActiveThreads,
    osi.max_workers_count - SUM(sch.active_workers_count) AS AvailableThreads,
    SUM(sch.runnable_tasks_count) AS WorkersWaitingForCpu,
    SUM(sch.pending_disk_io_count) AS RequestWaitingForThreads,
    SUM(sch.current_workers_count) AS AssociatedWorkers,
    CAST(
        100.0 * SUM(sch.active_workers_count) / osi.max_workers_count
        AS DECIMAL(10,6)
    ) AS [Percent.Active Threads]
FROM sys.dm_os_schedulers sch
CROSS JOIN sys.dm_os_sys_info osi
WHERE sch.status = 'VISIBLE ONLINE'
group by  osi.max_workers_count

go 

WITH WorkerStatus AS (
    SELECT 
        scheduler_id,
        current_tasks_count,
        runnable_tasks_count,
        current_workers_count,
        active_workers_count,
        CASE 
            WHEN runnable_tasks_count > 0 THEN ' Fila de execução'
            WHEN active_workers_count >= current_workers_count THEN ' Saturação de workers'
            ELSE ' Normal'
        END AS status
    FROM sys.dm_os_schedulers
    WHERE status = 'VISIBLE ONLINE'
)
SELECT 
    scheduler_id,
    current_tasks_count AS tarefas_ativas,
    runnable_tasks_count AS tarefas_na_fila,
    current_workers_count AS workers_em_uso,
    active_workers_count AS workers_ativos,
    status
FROM WorkerStatus
ORDER BY status DESC, scheduler_id;


SELECT 
    [object_name],
    [counter_name],
    [cntr_value] AS Page_Life_Expectancy_Seconds
FROM sys.dm_os_performance_counters
WHERE [counter_name] = 'Page life expectancy';


SELECT 
    node.cntr_value AS Page_Life_Expectancy_Seconds,
    mem.total_physical_memory_kb / 1024 AS Server_RAM_MB,
    node.object_name AS Buffer_Node
FROM sys.dm_os_performance_counters AS node
CROSS JOIN sys.dm_os_sys_memory AS mem
WHERE node.counter_name = 'Page life expectancy'
  AND node.object_name LIKE '%Buffer Node%';
