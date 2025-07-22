-- Script: Dynamic SMB Path Validation and Conditional Backup
-- Author: Bruno Martins
-- Description: This script dynamically tests SMB share paths using xp_cmdshell,
--              validates access by analyzing the command output, and runs a backup
--              only if at least one directory is confirmed accessible.


-- Enable xp_cmdshell temporarily
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'xp_cmdshell', 1;
RECONFIGURE;

-- Declare the list of SMB IPs to test
DECLARE @paths TABLE (IP NVARCHAR(100));
INSERT INTO @paths (IP) VALUES
('192.168.100.1'), ('192.168.100.2'), ('192.168.100.3'), ('192.168.100.4'),
('192.168.100.5'), ('192.168.100.6'), ('192.168.100.7'), ('192.168.100.8'),
('192.168.100.9'), ('192.168.100.10'), ('192.168.100.11'), ('192.168.100.12'),
('192.168.100.13'), ('192.168.100.14'), ('192.168.100.15'), ('192.168.100.16'),
('192.168.100.17');

-- Store valid paths
DECLARE @validPaths TABLE (Path NVARCHAR(500));
DECLARE @output TABLE (output NVARCHAR(4000));

-- Cursor loop to test each path with xp_cmdshell + dir
DECLARE @ip NVARCHAR(100), @path NVARCHAR(500), @cmd NVARCHAR(1000);
DECLARE ip_cursor CURSOR FOR SELECT IP FROM @paths;
OPEN ip_cursor;
FETCH NEXT FROM ip_cursor INTO @ip;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @path = '\\' + @ip + '\shared_folder';
    SET @cmd = 'cmd /c dir "' + @path + '"';

    BEGIN TRY
        DELETE FROM @output; -- Clear previous results

        INSERT INTO @output
        EXEC xp_cmdshell @cmd;

        IF NOT EXISTS (
            SELECT 1 FROM @output 
            WHERE output LIKE '%Access is denied.%'
               OR output LIKE '%The network path was not found.%'
               OR output LIKE '%The user name or password is incorrect.%'
               OR output LIKE '%Logon failure%'
               OR output LIKE '%System error%'
               OR output LIKE '%could not be found%'
        )
        BEGIN
            INSERT INTO @validPaths (Path) VALUES (@path);
        END
    END TRY
    BEGIN CATCH
        -- Continue on error
    END CATCH;

    FETCH NEXT FROM ip_cursor INTO @ip;
END

CLOSE ip_cursor;
DEALLOCATE ip_cursor;

-- Show the validated paths
SELECT * FROM @validPaths;

-- Build @Directory string with the first 4 valid paths
DECLARE @directoryList NVARCHAR(MAX) = '';
SELECT @directoryList = STRING_AGG(Path, ', ') WITHIN GROUP (ORDER BY Path)
FROM (
    SELECT Path
    FROM (
        SELECT Path, ROW_NUMBER() OVER (ORDER BY Path) AS rn
        FROM (SELECT DISTINCT Path FROM @validPaths) AS Dedup
    ) AS Ranked
    WHERE rn <= 4
) AS LimitedPaths;

-- Execute backup only if at least 1 path is valid
IF (SELECT COUNT(DISTINCT Path) FROM @validPaths) >= 1
BEGIN
    DECLARE @sql NVARCHAR(MAX) = '
    EXECUTE [dbo].[DatabaseBackup] 
        @Databases = ''MyDatabase'',
        @Directory = ''' + @directoryList + ''',
        @BackupType = ''LOG'',
        @Verify = ''N'',
        @CheckSum = ''N'',
        @CleanupTime = 330,
        @LogToTable = ''Y''
    ';
    
    PRINT 'Executing backup using the following directories: ' + @directoryList;
    EXEC sp_executesql @sql;
END
ELSE
BEGIN
    RAISERROR('Fewer than 1 accessible SMB directories are available.', 16, 1);
END

-- Disable xp_cmdshell after execution
EXEC sp_configure 'xp_cmdshell', 0;
RECONFIGURE;
EXEC sp_configure 'show advanced options', 0;
RECONFIGURE;
