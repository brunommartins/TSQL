/*
    Script: LogBackupFileCleanup.sql
    Author: Bruno de Melo Martins
    Description:
        This script scans multiple SMB directories for old SQL Server transaction log backup files (*.trn)
        and deletes those that are older than a specified retention period (default: 330 hours).

        It helps keep backup directories clean and avoids potential issues with disk usage and expired files.
        The script mimics the logic used by Ola Hallengren’s cleanup procedure, but gives more control and
        flexibility by checking each file’s last write time directly.

        This script temporarily enables xp_cmdshell, which must be allowed on the SQL Server instance.
        Use in a secure and controlled environment only.
*/

-- Enable xp_cmdshell temporarily
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'xp_cmdshell', 1;
RECONFIGURE;

-- Define retention period (in hours)
DECLARE @RetentionHours INT = 330;
DECLARE @CutoffDate DATETIME = DATEADD(HOUR, -@RetentionHours, GETDATE());

-- Define base folder (relative path shared across SMB IPs)
DECLARE @baseFolder NVARCHAR(300) = '\backup_share\cluster_name$AGName\DBName\LOG';

-- List of fake IPs for demonstration purposes
DECLARE @backupPaths TABLE (Directory NVARCHAR(500));
INSERT INTO @backupPaths (Directory)
VALUES 
('\\192.168.1.100' + @baseFolder),
('\\192.168.1.101' + @baseFolder),
('\\192.168.1.102' + @baseFolder),
('\\192.168.1.103' + @baseFolder),
('\\192.168.1.104' + @baseFolder);

-- Table to collect deletions
DECLARE @toDelete TABLE (FullPath NVARCHAR(1000));

-- Prepare loop variables
DECLARE @dir NVARCHAR(500), @cmd NVARCHAR(1000), @line NVARCHAR(4000);
DECLARE @output TABLE (line NVARCHAR(4000));

DECLARE path_cursor CURSOR FOR SELECT Directory FROM @backupPaths;
OPEN path_cursor;
FETCH NEXT FROM path_cursor INTO @dir;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @cmd = 'cmd /c dir "' + @dir + '\*.trn" /T:W';

    DELETE FROM @output;
    BEGIN TRY
        INSERT INTO @output
        EXEC xp_cmdshell @cmd;

        DECLARE @date NVARCHAR(20), @time NVARCHAR(20), @ampm NVARCHAR(10), @filename NVARCHAR(260), @fullpath NVARCHAR(1000);
        DECLARE line_cursor CURSOR FOR 
            SELECT line FROM @output 
            WHERE line LIKE ' %:%.trn';

        OPEN line_cursor;
        FETCH NEXT FROM line_cursor INTO @line;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Parse Windows DIR output
            SET @date     = LTRIM(SUBSTRING(@line, 1, 10));
            SET @time     = LTRIM(SUBSTRING(@line, 13, 5));
            SET @ampm     = LTRIM(SUBSTRING(@line, 19, 2));
            SET @filename = LTRIM(SUBSTRING(@line, 40, 260));

            IF @filename LIKE '%.trn'
            BEGIN
                DECLARE @fileDatetime DATETIME;
                SET @fileDatetime = TRY_CAST(@date + ' ' + @time + ' ' + @ampm AS DATETIME);

                IF @fileDatetime IS NOT NULL AND @fileDatetime < @CutoffDate
                BEGIN
                    SET @fullpath = @dir + '\' + @filename;
                    INSERT INTO @toDelete (FullPath) VALUES (@fullpath);
                END
            END

            FETCH NEXT FROM line_cursor INTO @line;
        END

        CLOSE line_cursor;
        DEALLOCATE line_cursor;
    END TRY
    BEGIN CATCH
        PRINT 'Error scanning directory: ' + @dir;
    END CATCH

    FETCH NEXT FROM path_cursor INTO @dir;
END

CLOSE path_cursor;
DEALLOCATE path_cursor;

-- Delete files
DECLARE @delPath NVARCHAR(1000), @delCmd NVARCHAR(1200);
DECLARE delete_cursor CURSOR FOR SELECT FullPath FROM @toDelete;
OPEN delete_cursor;
FETCH NEXT FROM delete_cursor INTO @delPath;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @delCmd = 'cmd /c IF EXIST "' + @delPath + '" del /Q "' + @delPath + '"';
    PRINT 'Deleting file: ' + @delPath;
    EXEC xp_cmdshell @delCmd;

    FETCH NEXT FROM delete_cursor INTO @delPath;
END

CLOSE delete_cursor;
DEALLOCATE delete_cursor;

-- Disable xp_cmdshell after execution
EXEC sp_configure 'xp_cmdshell', 0;
RECONFIGURE;
EXEC sp_configure 'show advanced options', 0;
RECONFIGURE;
