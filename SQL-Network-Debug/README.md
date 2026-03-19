# 🔎 SQL Server - Correlation: SPID, Thread, Network

## 📌 Objetivo

Este script permite correlacionar informações de execução do SQL Server com dados de rede e threads do sistema operacional, facilitando troubleshooting avançado de:

- Lentidão em queries
- Problemas de rede (latência, retransmission)
- Alto consumo de CPU
- Sessões específicas da aplicação

---

## 🔗 Correlação Completa

O script permite mapear:

SPID → Request → Task → Worker → Thread (Windows) → Conexão TCP

---

## 🚀 Script Principal

```sql
SELECT
    s.session_id                                   AS SPID,
    r.status,
    r.command,
    r.cpu_time,
    r.total_elapsed_time,
    r.wait_type,
    r.wait_time,

    -- Worker / Thread
    t.scheduler_id,
    w.state                                        AS worker_state,
    th.os_thread_id,

    -- Network
    c.client_net_address                           AS client_ip,
    c.local_net_address                            AS server_ip,
    c.client_tcp_port,
    c.local_tcp_port,
    c.net_transport,
    c.protocol_type,
    c.encrypt_option,
    c.auth_scheme,
    c.net_packet_size,

    -- Volume (proxy de tráfego)
    s.reads,
    s.writes,
    c.num_reads,
    c.num_writes,

    -- Identificação
    s.host_name,
    s.program_name,
    s.login_name,

    -- Tempo
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
ORDER BY r.cpu_time DESC, s.reads DESC



🎯 Uso prático
1. Identificar sessão problemática

CPU alta
wait elevado
volume alto de reads/writes

2. Capturar dados da conexão
client_ip
client_tcp_port
🌐 Análise de rede (Wireshark)

Filtro:

tcp.port == <porta>

Exemplo:

tcp.port == 57058
📡 Captura de rede (Windows)
netsh trace start capture=yes IPv4.Address=(IP_CLIENTE,IP_SERVIDOR) tracefile=c:\temp\trace.etl

Finalizar:
netsh trace stop

Converter:
etl2pcapng.exe trace.etl trace.pcapng
⚠️ Limitações

O SQL Server NÃO expõe:

Pacotes TCP individuais
Retransmissions
Packet loss

Para isso, utilize:

Wireshark
netsh trace
ETW

🔥 Cenários suportados

Troubleshooting de INSERT lento
Problemas de CDC / DataHub
ASYNC_NETWORK_IO
Lentidão intermitente de aplicação
Diagnóstico com Microsoft Support

🧠 Dicas

Combine com Query Store para identificar queries críticas
Combine com Wireshark para validar retransmission
Combine com waits para identificar gargalo real

