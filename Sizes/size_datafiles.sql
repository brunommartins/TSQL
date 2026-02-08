;WITH FileInfo AS
(
    SELECT
        mf.database_id,
        DB_NAME(mf.database_id)            AS DatabaseName,
        mf.file_id,
        mf.type_desc                       AS FileType,
        mf.name                            AS LogicalName,
        mf.physical_name                   AS PhysicalName,
        vs.volume_mount_point              AS VolumeMountPoint,
        vs.file_system_type                AS FileSystem,

        CAST(mf.size / 128.0 / 1024 AS DECIMAL(18,2)) AS FileSize_GB,

        CAST(
            CASE 
                WHEN mf.type_desc = 'LOG' 
                    THEN NULL
                ELSE (mf.size - FILEPROPERTY(mf.name,'SpaceUsed')) / 128.0 / 1024
            END 
            AS DECIMAL(18,2)
        ) AS FileFreeInside_GB,

        CAST(vs.total_bytes / 1024.0 / 1024 / 1024 AS DECIMAL(18,2))     AS DiskTotal_GB,
        CAST(vs.available_bytes / 1024.0 / 1024 / 1024 AS DECIMAL(18,2)) AS DiskFree_GB,
        CAST((vs.available_bytes * 100.0) / NULLIF(vs.total_bytes,0) AS DECIMAL(6,2)) AS DiskFree_Pct,

        mf.is_percent_growth,
        mf.growth,
        mf.max_size
    FROM sys.master_files mf
    CROSS APPLY sys.dm_os_volume_stats(mf.database_id, mf.file_id) vs
),
GrowthCalc AS
(
    SELECT
        *,
        CAST(
            CASE 
                WHEN max_size = -1 THEN NULL                                  -- ilimitado
                WHEN max_size = 0  THEN 0                                     -- sem crescimento
                ELSE (max_size / 128.0 / 1024)                                -- max_size em páginas de 8KB
            END 
            AS DECIMAL(18,2)
        ) AS FileMaxSize_GB,

        CAST(
            CASE 
                WHEN max_size <= 0 THEN 0
                WHEN max_size = -1 THEN NULL
                ELSE ( (max_size - (FileSize_GB * 1024.0 * 1024 * 1024) / (8.0*1024) ) / 128.0 / 1024 )
            END
            AS DECIMAL(18,2)
        ) AS PotentialGrowthToMax_GB
    FROM FileInfo
)
SELECT
    DatabaseName,
    FileType,
    LogicalName,
    PhysicalName,
    VolumeMountPoint,
    FileSystem,

    FileSize_GB,
    FileFreeInside_GB,

    DiskTotal_GB,
    DiskFree_GB,
    DiskFree_Pct,

    FileMaxSize_GB,
    PotentialGrowthToMax_GB,

    CASE 
        WHEN FileMaxSize_GB IS NULL THEN 'ILIMITADO'
        WHEN PotentialGrowthToMax_GB <= 0 THEN 'SEM CRESCIMENTO'
        WHEN DiskFree_GB >= PotentialGrowthToMax_GB THEN 'OK'
        ELSE 'INSUFICIENTE'
    END AS DiskEnough_ForMaxGrowth
FROM GrowthCalc
 where DatabaseName = 'Controly' 
ORDER BY DatabaseName, FileType, LogicalName;
