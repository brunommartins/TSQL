
---

# 📄 spid_network_thread.sql

```sql
/*
Script: SPID + Thread + Network Correlation
Author: Bruno Martins
Description:
Correlates SQL Server sessions with OS threads and network information.
*/

SET NOCOUNT ON;

SELECT
    s.session_id                                   AS SPID,
    r.status,
    r.command,
    r.cpu_time,
    r.total_elapsed_time,
    r.wait_type,
    r.wait_time,

    t.scheduler_id,
    w.state                                        AS worker_state,
    th.os_thread_id,

    c.client_net_address                           AS client_ip,
    c.local_net_address                            AS server_ip,
    c.client_tcp_port,
    c.local_tcp_port,
    c.net_transport,
    c.protocol_type,
    c.encrypt_option,
    c.auth_scheme,
    c.net_packet_size,

    s.reads,
    s.writes,
    c.num_reads,
    c.num_writes,

    s.host_name,
    s.program_name,
    s.login_name,

    s.last_request_end_time,
    DATEDIFF(ms, s.last_request_end_time, SYSDATETIME()) AS ms_from_last_request

FROM sys.dm_exec_sessions s
LEFT JOIN sys.dm_exec_requests r
    ON s.session_id = r.session_id
LEFT JOIN sys.dm_exec_connections c
    ON s.session_id = c.session_id
LEFT JOIN sys.dm_os_tasks t
    ON r.task_address = t.task_address
LEFT JOIN sys.dm_os_workers w
    ON t.worker_address = w.worker_address
LEFT JOIN sys.dm_os_threads th
    ON w.thread_address = th.thread_address

WHERE s.is_user_process = 1
ORDER BY r.cpu_time DESC, s.reads DESC;
