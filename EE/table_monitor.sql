
CREATE EVENT SESSION [Table_Monitoring] ON SERVER 
ADD EVENT sqlos.wait_completed(SET collect_wait_resource=(1)
    ACTION(package0.collect_cpu_cycle_time,package0.collect_current_thread_id,package0.collect_system_time,package0.event_sequence,package0.process_id,sqlos.cpu_id,sqlos.scheduler_address,sqlos.scheduler_id,sqlserver.client_connection_id,sqlserver.client_pid,sqlserver.context_info,sqlserver.database_id,sqlserver.is_system,sqlserver.num_response_rows,sqlserver.query_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.transaction_id,sqlserver.transaction_sequence)
    WHERE ([duration]>=(100) AND [sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text],N'%insert into SPI.LCO_LANCAMENTO_CONSOLIDACAO%')))
ADD TARGET package0.event_file(SET filename=N'Table_Monitoring',max_file_size=(200),max_rollover_files=(20))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO
