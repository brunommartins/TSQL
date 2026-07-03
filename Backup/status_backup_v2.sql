SELECT
    er.session_id,
    er.start_time,
    er.status,
    er.command,
    er.percent_complete,
    er.estimated_completion_time / 60 / 1000 AS estimate_completion_minutes,
    DATEADD(MINUTE, (er.estimated_completion_time / 60 / 1000), GETDATE()) AS estimated_completion_time,

    FileInfo.backup_restore_file,

    CASE
        WHEN FileInfo.backup_restore_file IS NOT NULL THEN
            RIGHT(
                REPLACE(FileInfo.backup_restore_file, '\', '/'),
                CHARINDEX('/', REVERSE(REPLACE(FileInfo.backup_restore_file, '\', '/')) + '/') - 1
            )
    END AS backup_restore_filename,

    Cmd.query_text,

    es.login_name,
    es.host_name,
    es.program_name,
    er.wait_type,
    er.wait_time,
    er.last_wait_type,
    er.wait_resource
FROM sys.dm_exec_connections ec
LEFT OUTER JOIN sys.dm_exec_sessions es
    ON ec.session_id = es.session_id
LEFT OUTER JOIN sys.dm_exec_requests er
    ON ec.connection_id = er.connection_id
OUTER APPLY sys.dm_exec_sql_text(er.sql_handle) st
OUTER APPLY sys.dm_exec_query_plan(er.plan_handle) ph
OUTER APPLY
(
    SELECT
        query_text =
            SUBSTRING(
                st.text,
                er.statement_start_offset / 2,
                (
                    CASE
                        WHEN er.statement_end_offset = -1
                            THEN LEN(CONVERT(nvarchar(max), st.text)) * 2
                        ELSE er.statement_end_offset
                    END - er.statement_start_offset
                ) / 2
            )
) Cmd
OUTER APPLY
(
    SELECT
        pos_disk = NULLIF(PATINDEX('%DISK%=%''%', Cmd.query_text), 0),
        pos_disk_n = NULLIF(PATINDEX('%DISK%=N''%', Cmd.query_text), 0),
        pos_url = NULLIF(PATINDEX('%URL%=%''%', Cmd.query_text), 0),
        pos_url_n = NULLIF(PATINDEX('%URL%=N''%', Cmd.query_text), 0)
) P
OUTER APPLY
(
    SELECT
        start_pos =
            CASE
                WHEN P.pos_disk_n IS NOT NULL THEN CHARINDEX('''', Cmd.query_text, P.pos_disk_n)
                WHEN P.pos_disk IS NOT NULL THEN CHARINDEX('''', Cmd.query_text, P.pos_disk)
                WHEN P.pos_url_n IS NOT NULL THEN CHARINDEX('''', Cmd.query_text, P.pos_url_n)
                WHEN P.pos_url IS NOT NULL THEN CHARINDEX('''', Cmd.query_text, P.pos_url)
            END
) S
OUTER APPLY
(
    SELECT
        end_pos =
            CASE
                WHEN S.start_pos IS NOT NULL THEN CHARINDEX('''', Cmd.query_text, S.start_pos + 1)
            END
) E
OUTER APPLY
(
    SELECT
        backup_restore_file =
            CASE
                WHEN S.start_pos IS NOT NULL
                 AND E.end_pos IS NOT NULL
                 AND E.end_pos > S.start_pos
                THEN SUBSTRING(Cmd.query_text, S.start_pos + 1, E.end_pos - S.start_pos - 1)
            END
) FileInfo
WHERE er.command IN
(
    'BACKUP DATABASE',
    'BACKUP LOG',
    'RESTORE DATABASE',
    'RESTORE LOG',
    'RESTORE HEADERONLY'
)
ORDER BY
    es.program_name DESC;
