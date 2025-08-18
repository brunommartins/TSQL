-- Backup/Restore progress & waits – versão aprimorada
--Consulta que lista operações de BACKUP/RESTORE em andamento no SQL Server, mostrando % concluído, tempo decorrido, ETA, waits e sessão bloqueadora — útil para acompanhar jobs/restores longos.

SET NOCOUNT ON;

SELECT
    er.session_id,
    DB_NAME(er.database_id)              AS database_name,         -- pode ser NULL em RESTORE HEADERONLY
    er.start_time,
    er.status,
    er.command,
    er.percent_complete,
    -- tempos
    er.total_elapsed_time / 1000.0 / 60  AS elapsed_minutes,
    CASE 
        WHEN er.estimated_completion_time > 0 
             THEN er.estimated_completion_time / 1000.0 / 60 
        ELSE NULL 
    END                                  AS remaining_minutes,
    DATEADD(ms, er.estimated_completion_time, SYSDATETIME()) AS estimated_completion_datetime,

    -- instrução atual
    SUBSTRING(st.text,
              (er.statement_start_offset / 2) + 1,
              (CASE WHEN er.statement_end_offset = -1 
                    THEN LEN(CONVERT(nvarchar(max), st.text)) * 2 
                    ELSE er.statement_end_offset END - er.statement_start_offset) / 2) AS statement_text,

    -- identidade do chamador
    es.login_name,
    es.host_name,
    es.program_name,

    -- esperas atuais e últimas
    er.wait_type,
    er.wait_time,
    er.last_wait_type,
    er.wait_resource,

    -- sinais úteis
    er.blocking_session_id,
    er.cpu_time,
    er.reads,
    er.writes
FROM sys.dm_exec_requests         AS er
JOIN sys.dm_exec_sessions         AS es ON es.session_id = er.session_id
LEFT JOIN sys.dm_exec_connections AS ec ON ec.session_id = er.session_id
OUTER APPLY sys.dm_exec_sql_text(er.sql_handle)        AS st
OUTER APPLY sys.dm_exec_query_plan(er.plan_handle)     AS ph
WHERE er.command IN (
    'BACKUP DATABASE','BACKUP LOG',
    'RESTORE DATABASE','RESTORE LOG','RESTORE HEADERONLY'
)
ORDER BY er.start_time DESC;
