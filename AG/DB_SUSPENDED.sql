-- Loop por todas as bases em AG que estão suspensas e aplica RESUME
DECLARE @db_name SYSNAME, @sql NVARCHAR(500);

DECLARE db_cursor CURSOR FOR
SELECT drs.database_name
FROM sys.dm_hadr_database_replica_states drs
JOIN sys.databases d ON d.name = drs.database_name
WHERE drs.synchronization_state_desc = 'SUSPENDED'
  AND drs.is_suspended = 1;

OPEN db_cursor;
FETCH NEXT FROM db_cursor INTO @db_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT '>> Encontrada base em estado SUSPENDED: ' + @db_name;
    
    SET @sql = 'ALTER DATABASE [' + @db_name + '] SET HADR RESUME';
    PRINT '>> Executando: ' + @sql;
    
    BEGIN TRY
        EXEC (@sql);
        PRINT ' Database [' + @db_name + '] resumida com sucesso.';
    END TRY
    BEGIN CATCH
        PRINT ' Erro ao resumir [' + @db_name + ']: ' + ERROR_MESSAGE();
    END CATCH;

    FETCH NEXT FROM db_cursor INTO @db_name;
END

CLOSE db_cursor;
DEALLOCATE db_cursor;
