SELECT  
    vs.volume_mount_point        AS Unidade,
    vs.file_system_type          AS FileSystem,
    CAST(vs.total_bytes / 1024.0 / 1024 / 1024 AS DECIMAL(10,2)) AS Total_GB,
    CAST(vs.available_bytes / 1024.0 / 1024 / 1024 AS DECIMAL(10,2)) AS Livre_GB,
    CAST(
        (vs.available_bytes * 100.0) / vs.total_bytes 
        AS DECIMAL(5,2)
    ) AS Percentual_Livre
FROM sys.master_files mf
CROSS APPLY sys.dm_os_volume_stats(mf.database_id, mf.file_id) vs
GROUP BY 
    vs.volume_mount_point,
    vs.file_system_type,
    vs.total_bytes,
    vs.available_bytes
ORDER BY Unidade;
