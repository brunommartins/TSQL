/*
Log_Send_Queue_Size_KB: Quantidade de logs pendentes de envio para a réplica secundária.
Log_Send_Rate_KBps: Velocidade de envio dos logs (KB/s).
Redo_Queue_Size_KB: Tamanho da fila de redo pendente na réplica secundária.
Redo_Rate_KBps: Velocidade de processamento do redo (KB/s).
Estimated_Log_Send_Time_Seconds: Tempo estimado (em segundos) para concluir o envio dos logs.
Estimated_Redo_Time_Seconds: Tempo estimado (em segundos) para aplicar as transações na réplica secundária.
Caso a taxa de envio (Log_Send_Rate_KBps) ou a taxa de redo (Redo_Rate_KBps) seja zero, o tempo estimado aparecerá como NULL, pois o cálculo não pode ser realizado.
Estimated_Log_Send_Completion_Time: Horário estimado para a conclusão do envio dos logs.
Estimated_Redo_Completion_Time: Horário estimado para a conclusão do redo.

*/
SELECT 
    ag.name AS AG_Name,
    ar.replica_server_name AS Replica_Name,
    drs.database_id,
    db_name(drs.database_id) AS Database_Name,
    drs.log_send_queue_size AS Log_Send_Queue_Size_KB,  -- Tamanho da fila de envio de logs (KB)
    drs.log_send_rate AS Log_Send_Rate_KBps,           -- Taxa de envio de logs (KB/s)
    drs.redo_queue_size AS Redo_Queue_Size_KB,         -- Tamanho da fila de redo (KB)
    drs.redo_rate AS Redo_Rate_KBps,                   -- Taxa de processamento do redo (KB/s)

    -- Tempo estimado para envio e aplicação do redo
    CASE 
        WHEN drs.log_send_rate > 0 
        THEN CAST(drs.log_send_queue_size / drs.log_send_rate AS DECIMAL(10,2))
        ELSE NULL 
    END AS Estimated_Log_Send_Time_Seconds,            

    CASE 
        WHEN drs.redo_rate > 0 
        THEN CAST(drs.redo_queue_size / drs.redo_rate AS DECIMAL(10,2))
        ELSE NULL 
    END AS Estimated_Redo_Time_Seconds,                

    -- Horário estimado de conclusão do envio e do redo
    DATEADD(SECOND, 
        CASE 
            WHEN drs.log_send_rate > 0 
            THEN drs.log_send_queue_size / drs.log_send_rate 
            ELSE 0 
        END, GETDATE()) AS Estimated_Log_Send_Completion_Time,

    DATEADD(SECOND, 
        CASE 
            WHEN drs.redo_rate > 0 
            THEN drs.redo_queue_size / drs.redo_rate 
            ELSE 0 
        END, GETDATE()) AS Estimated_Redo_Completion_Time       

    ---- Percentual de conclusão do envio de logs
    --CASE 
    --    WHEN (drs.log_send_queue_size + drs.log_send_rate) > 0 
    --    THEN CAST(100 * (1 - (CAST(drs.log_send_queue_size AS FLOAT) / 
    --        NULLIF(CAST(drs.log_send_queue_size + drs.log_send_rate AS FLOAT), 0))) AS DECIMAL(5,2))
    --    ELSE 100 
    --END AS Log_Send_Completion_Percentage,

    ---- Percentual de conclusão do redo
    --CASE 
    --    WHEN (drs.redo_queue_size + drs.redo_rate) > 0 
    --    THEN CAST(100 * (1 - (CAST(drs.redo_queue_size AS FLOAT) / 
    --        NULLIF(CAST(drs.redo_queue_size + drs.redo_rate AS FLOAT), 0))) AS DECIMAL(5,2))
    --    ELSE 100 
    --END AS Redo_Completion_Percentage

FROM sys.dm_hadr_database_replica_states drs
JOIN sys.availability_replicas ar 
    ON drs.replica_id = ar.replica_id
JOIN sys.availability_groups ag 
    ON ar.group_id = ag.group_id
WHERE drs.is_local = 0  -- Foca nos dados da réplica secundária
ORDER BY AG_Name, Database_Name;
