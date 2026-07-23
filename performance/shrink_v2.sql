SET NOCOUNT ON;

DECLARE 
    @Execute            bit = 0,      -- 0 = somente mostra o que faria | 1 = executa
    @MarginMB           int = 10240,  -- margem livre que vai manter em cada arquivo, exemplo 10 GB
    @ShrinkStepMB       int = 1000,   -- reduz em blocos de 1000 MB
    @MinFreePercent     decimal(5,2) = 20.00; -- so tenta shrink se free >= 20%

DECLARE 
    @FileName sysname,
    @PhysicalName nvarchar(260),
    @CurrentSizeMB int,
    @UsedSizeMB int,
    @FreeSizeMB int,
    @FreePercent decimal(10,2),
    @TargetSizeMB int,
    @NextSizeMB int,
    @sql nvarchar(max);

IF OBJECT_ID('tempdb..#FilesToShrink') IS NOT NULL
    DROP TABLE #FilesToShrink;

CREATE TABLE #FilesToShrink
(
    file_id int,
    file_name sysname,
    physical_name nvarchar(260),
    current_size_mb int,
    used_size_mb int,
    free_size_mb int,
    free_percent decimal(10,2),
    target_size_mb int
);

INSERT INTO #FilesToShrink
(
    file_id,
    file_name,
    physical_name,
    current_size_mb,
    used_size_mb,
    free_size_mb,
    free_percent,
    target_size_mb
)
SELECT
    df.file_id,
    df.name AS file_name,
    df.physical_name,
    CAST(df.size / 128.0 AS int) AS current_size_mb,
    CAST(FILEPROPERTY(df.name, 'SpaceUsed') / 128.0 AS int) AS used_size_mb,
    CAST((df.size - FILEPROPERTY(df.name, 'SpaceUsed')) / 128.0 AS int) AS free_size_mb,
    CAST(
        100.0 * 
        ((df.size - FILEPROPERTY(df.name, 'SpaceUsed')) / 128.0) / 
        NULLIF((df.size / 128.0), 0)
        AS decimal(10,2)
    ) AS free_percent,
    CAST((FILEPROPERTY(df.name, 'SpaceUsed') / 128.0) + @MarginMB AS int) AS target_size_mb
FROM sys.database_files df
WHERE 
    df.type_desc = 'ROWS' -- somente MDF/NDF
    AND df.state_desc = 'ONLINE';

-- Ajuste de seguranca: nunca deixar target maior que o tamanho atual
UPDATE #FilesToShrink
SET target_size_mb = current_size_mb
WHERE target_size_mb > current_size_mb;

-- Mostra o plano antes
SELECT
    DB_NAME() AS database_name,
    file_name,
    physical_name,
    current_size_mb,
    used_size_mb,
    free_size_mb,
    free_percent,
    target_size_mb,
    current_size_mb - target_size_mb AS estimated_reduction_mb,
    CASE 
        WHEN current_size_mb <= target_size_mb THEN 'NAO EXECUTAR: arquivo ja esta no tamanho alvo ou menor'
        WHEN free_percent < @MinFreePercent THEN 'NAO EXECUTAR: percentual livre abaixo do minimo definido'
        ELSE 'CANDIDATO AO SHRINK'
    END AS action_status
FROM #FilesToShrink
ORDER BY file_name;

IF @Execute = 0
BEGIN
    PRINT 'Modo preview ativo. Nenhum shrink foi executado.';
    PRINT 'Para executar, altere @Execute para 1.';
    RETURN;
END;

DECLARE cur_files CURSOR LOCAL FAST_FORWARD FOR
SELECT
    file_name,
    physical_name,
    current_size_mb,
    used_size_mb,
    free_size_mb,
    free_percent,
    target_size_mb
FROM #FilesToShrink
WHERE 
    current_size_mb > target_size_mb
    AND free_percent >= @MinFreePercent
ORDER BY file_name;

OPEN cur_files;

FETCH NEXT FROM cur_files INTO 
    @FileName,
    @PhysicalName,
    @CurrentSizeMB,
    @UsedSizeMB,
    @FreeSizeMB,
    @FreePercent,
    @TargetSizeMB;

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT '============================================================';
    PRINT 'Banco: ' + DB_NAME();
    PRINT 'Arquivo: ' + @FileName;
    PRINT 'Caminho: ' + @PhysicalName;
    PRINT 'Tamanho atual MB: ' + CAST(@CurrentSizeMB AS varchar(20));
    PRINT 'Usado MB: ' + CAST(@UsedSizeMB AS varchar(20));
    PRINT 'Livre MB: ' + CAST(@FreeSizeMB AS varchar(20));
    PRINT 'Livre %: ' + CAST(@FreePercent AS varchar(20));
    PRINT 'Tamanho alvo MB: ' + CAST(@TargetSizeMB AS varchar(20));
    PRINT 'Inicio: ' + CONVERT(varchar(30), GETDATE(), 120);

    SET @NextSizeMB = @CurrentSizeMB - @ShrinkStepMB;

    WHILE @NextSizeMB > @TargetSizeMB
    BEGIN
        PRINT 'Executando DBCC SHRINKFILE em ' + @FileName + ' para ' + CAST(@NextSizeMB AS varchar(20)) + ' MB - ' + CONVERT(varchar(30), GETDATE(), 120);

        SET @sql = N'DBCC SHRINKFILE (' + QUOTENAME(@FileName, '''') + N', ' + CAST(@NextSizeMB AS nvarchar(20)) + N') WITH NO_INFOMSGS;';
        EXEC sys.sp_executesql @sql;

        SET @NextSizeMB = @NextSizeMB - @ShrinkStepMB;
    END;

    PRINT 'Executando ajuste final DBCC SHRINKFILE em ' + @FileName + ' para ' + CAST(@TargetSizeMB AS varchar(20)) + ' MB - ' + CONVERT(varchar(30), GETDATE(), 120);

    SET @sql = N'DBCC SHRINKFILE (' + QUOTENAME(@FileName, '''') + N', ' + CAST(@TargetSizeMB AS nvarchar(20)) + N') WITH NO_INFOMSGS;';
    EXEC sys.sp_executesql @sql;

    PRINT 'Fim arquivo: ' + @FileName + ' - ' + CONVERT(varchar(30), GETDATE(), 120);

    FETCH NEXT FROM cur_files INTO 
        @FileName,
        @PhysicalName,
        @CurrentSizeMB,
        @UsedSizeMB,
        @FreeSizeMB,
        @FreePercent,
        @TargetSizeMB;
END;

CLOSE cur_files;
DEALLOCATE cur_files;

PRINT '============================================================';
PRINT 'Processo finalizado.';

SELECT
    DB_NAME() AS database_name,
    df.name AS file_name,
    df.physical_name,
    CAST(df.size / 128.0 AS int) AS current_size_mb,
    CAST(FILEPROPERTY(df.name, 'SpaceUsed') / 128.0 AS int) AS used_size_mb,
    CAST((df.size - FILEPROPERTY(df.name, 'SpaceUsed')) / 128.0 AS int) AS free_size_mb,
    CAST(
        100.0 * 
        ((df.size - FILEPROPERTY(df.name, 'SpaceUsed')) / 128.0) / 
        NULLIF((df.size / 128.0), 0)
        AS decimal(10,2)
    ) AS free_percent
FROM sys.database_files df
WHERE df.type_desc = 'ROWS'
ORDER BY df.name;
