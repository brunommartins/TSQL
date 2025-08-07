-- bancos em SIMPLE vão aparecer com LastLogBackup = NULL por padrão. Se quiser incluir copy_only, basta remover o filtro AND b.is_copy_only = 0.

SELECT 
    db.name AS Name,
    db.state_desc AS Status,
    SUSER_SNAME(db.owner_sid) AS Owner,
    db.recovery_model_desc AS RecoveryModel,
    db.compatibility_level AS CompatibilityLevel,
    CONVERT(decimal(16,2), SUM(CAST(mf.size AS BIGINT)) * 8.0 / 1024 / 1024) AS SizeGB,

    -- Último FULL
    (
        SELECT MAX(b.backup_finish_date)
        FROM msdb.dbo.backupset AS b
        WHERE b.database_name = db.name COLLATE database_default
          AND b.type = 'D'              -- Full
          AND b.is_copy_only = 0
    ) AS LastFullBackup,

    -- Último DIFF
    (
        SELECT MAX(b.backup_finish_date)
        FROM msdb.dbo.backupset AS b
        WHERE b.database_name = db.name COLLATE database_default
          AND b.type = 'I'              -- Differential
          AND b.is_copy_only = 0
    ) AS LastDiffBackup,

    -- Último LOG
    (
        SELECT MAX(b.backup_finish_date)
        FROM msdb.dbo.backupset AS b
        WHERE b.database_name = db.name COLLATE database_default
          AND b.type = 'L'              -- Log
          AND b.is_copy_only = 0
    ) AS LastLogBackup

FROM sys.databases AS db
LEFT JOIN sys.master_files AS mf 
       ON db.database_id = mf.database_id
GROUP BY 
    db.name, db.state_desc, db.owner_sid, db.recovery_model_desc, db.compatibility_level;
