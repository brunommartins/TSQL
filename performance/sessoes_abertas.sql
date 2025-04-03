SELECT
    host_name,
    COUNT(session_id) AS [open]
FROM
    sys.dm_exec_sessions
WHERE
    is_user_process = 1
GROUP BY
    host_name
ORDER BY
    [open] DESC;


SELECT 
    s.host_name,
    COUNT(*) AS session_count
FROM 
    sys.dm_exec_sessions AS s
WHERE 
    s.is_user_process = 1 -- ignora processos internos do sistema
   -- AND s.status = 'running' -- ou 'sleeping' se quiser incluir conexões ociosas
GROUP BY 
    s.host_name
ORDER BY 
    session_count DESC;



	SELECT 
    s.host_name,
    s.program_name,
    s.login_name,
    COUNT(*) AS session_count
FROM 
    sys.dm_exec_sessions AS s
LEFT JOIN 
    sys.dm_exec_requests AS r ON s.session_id = r.session_id
WHERE 
    s.is_user_process = 1
   -- AND (r.session_id IS NOT NULL OR s.status = 'running') -- só pega sessões com atividade ou realmente ativas
GROUP BY 
    s.host_name, s.program_name, s.login_name
ORDER BY 
    session_count DESC;





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
    COUNT(*) OVER (PARTITION BY s.host_name) AS session_count_per_host
FROM 
    sys.dm_exec_requests AS r
JOIN 
    sys.dm_exec_sessions AS s ON r.session_id = s.session_id
WHERE 
    s.is_user_process = 1
    -- AND DB_NAME(r.database_id) = 'SeuBancoAqui' -- descomente e substitua se quiser filtrar
ORDER BY 
    r.total_elapsed_time DESC;
