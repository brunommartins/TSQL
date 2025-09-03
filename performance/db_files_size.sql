SELECT 
    df.file_id,
    df.name                       AS file_name,
    df.physical_name,
    df.type_desc                  AS file_type,
    fg.name                       AS filegroup_name,
    fg.type_desc                  AS filegroup_type,

    -- tamanho atual
    CONVERT(bigint, df.size) * 8 / 1024          AS size_MB,
    CONVERT(decimal(19,2),
            CONVERT(bigint, df.size) * 8.0 / 1024 / 1024) AS size_GB,

    -- max_size (-1 = ilimitado, 268435456 = 2 TB em páginas)
    CASE df.max_size
        WHEN -1 THEN CAST(NULL AS bigint)                   -- ilimitado
        ELSE CONVERT(bigint, df.max_size) * 8 / 1024
    END                                         AS max_size_MB,
    CASE df.max_size
        WHEN -1 THEN NULL
        ELSE CONVERT(decimal(19,2),
                    CONVERT(bigint, df.max_size) * 8.0 / 1024 / 1024)
    END                                         AS max_size_GB,

    -- autogrowth
    CASE 
        WHEN df.is_percent_growth = 1
            THEN CONCAT(df.growth, '%')
        ELSE CONCAT(CONVERT(bigint, df.growth) * 8 / 1024, ' MB')
    END                                         AS auto_growth,

    df.is_percent_growth
FROM sys.database_files AS df
LEFT JOIN sys.filegroups AS fg
       ON df.data_space_id = fg.data_space_id
ORDER BY fg.name, df.file_id;
