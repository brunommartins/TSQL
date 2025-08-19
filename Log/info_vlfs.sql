-- Retorna o ID numérico do banco
SELECT DB_ID('dbname');

-- Lista todas as informações de VLFs (Virtual Log Files) do log de transações do banco com ID = 42
SELECT * 
FROM sys.dm_db_log_info(42);

-- Agrupa por arquivo e status (ativo ou inativo), mostrando a contagem de VLFs em cada condição
SELECT file_id, vlf_active, COUNT(*) AS VLF_Count
FROM sys.dm_db_log_info(42)
GROUP BY file_id, vlf_active;


SELECT d.name AS database_name,
       COUNT(*) AS total_vlfs,
       SUM(CASE WHEN li.vlf_active=1 THEN 1 ELSE 0 END) AS active_vlfs,
       CAST(100.0*SUM(CASE WHEN li.vlf_active=1 THEN 1 ELSE 0 END)/NULLIF(COUNT(*),0) AS decimal(5,2)) AS pct_active
FROM sys.databases d
CROSS APPLY sys.dm_db_log_info(d.database_id) li
WHERE d.state = 0
GROUP BY d.name
ORDER BY total_vlfs DESC, d.name;


/* ===========================================================
   VLF Overview (per DB and per log file)
   - Requer: VIEW SERVER STATE e VIEW DATABASE STATE (por DB)
   - Compatível: SQL Server 2016 SP2+ (dm_db_log_info)
   ===========================================================*/

DECLARE @DbName sysname = NULL; -- ex.: N'AdventureWorks2019' ou NULL para todos

;WITH Dbs AS (
    SELECT d.database_id, d.name
    FROM sys.databases AS d
    WHERE (@DbName IS NULL OR d.name = @DbName)
      AND d.state = 0 /* ONLINE */
),
LogInfo AS (
    SELECT
        db.name                           AS database_name,
        db.database_id,
        li.file_id,
        li.vlf_active,
        li.vlf_size_mb
    FROM Dbs AS db
    CROSS APPLY sys.dm_db_log_info(db.database_id) AS li
),
Agg AS (
    SELECT
        database_name,
        database_id,
        file_id,
        COUNT(*)                          AS total_vlfs,
        SUM(CASE WHEN vlf_active = 1 THEN 1 ELSE 0 END) AS active_vlfs,
        SUM(CASE WHEN vlf_active = 0 THEN 1 ELSE 0 END) AS inactive_vlfs,
        CAST(SUM(vlf_size_mb) AS decimal(18,2))         AS total_vlf_size_mb,
        CAST(AVG(CAST(vlf_size_mb AS decimal(18,2))) AS decimal(18,2)) AS avg_vlf_size_mb
    FROM LogInfo
    GROUP BY database_name, database_id, file_id
),
DBFiles AS (
    SELECT database_id, file_id, size_mb = CAST(size/128.0 AS decimal(18,2))
    FROM sys.master_files
    WHERE type_desc = 'LOG'
),
PerFile AS (
    SELECT
        a.database_name,
        a.database_id,
        a.file_id,
        a.total_vlfs,
        a.active_vlfs,
        a.inactive_vlfs,
        pct_active = CAST(100.0 * a.active_vlfs / NULLIF(a.total_vlfs,0) AS decimal(5,2)),
        a.total_vlf_size_mb,
        a.avg_vlf_size_mb,
        log_file_size_mb = f.size_mb
    FROM Agg AS a
    LEFT JOIN DBFiles AS f
      ON f.database_id = a.database_id
     AND f.file_id     = a.file_id
),
PerDb AS (
    SELECT
        database_name,
        database_id,
        total_vlfs     = SUM(total_vlfs),
        active_vlfs    = SUM(active_vlfs),
        inactive_vlfs  = SUM(inactive_vlfs),
        pct_active     = CAST(100.0 * SUM(active_vlfs) / NULLIF(SUM(total_vlfs),0) AS decimal(5,2)),
        total_log_mb   = CAST(SUM(log_file_size_mb) AS decimal(18,2)),
        total_vlf_mb   = CAST(SUM(total_vlf_size_mb) AS decimal(18,2)),
        avg_vlf_size_mb= CAST(AVG(avg_vlf_size_mb) AS decimal(18,2)),
        log_files      = COUNT(DISTINCT file_id)
    FROM PerFile
    GROUP BY database_name, database_id
)

-- 1) RESUMO POR BANCO
SELECT
    database_name,
    database_id,
    log_files,
    total_log_mb,
    total_vlfs,
    active_vlfs,
    inactive_vlfs,
    pct_active,
    total_vlf_mb,
    avg_vlf_size_mb
FROM PerDb
ORDER BY total_vlfs DESC, database_name;

-- 2) DETALHE POR ARQUIVO DE LOG
SELECT
    database_name,
    database_id,
    file_id,
    log_file_size_mb,
    total_vlfs,
    active_vlfs,
    inactive_vlfs,
    pct_active,
    total_vlf_size_mb,
    avg_vlf_size_mb
FROM PerFile
ORDER BY database_name, file_id;
