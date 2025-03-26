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



	SELECT hostname, count(*)
    
FROM
    sys.sysprocesses
	group by hostname
