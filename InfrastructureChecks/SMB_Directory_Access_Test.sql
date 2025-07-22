/*******************************************************************************************
 Script Name : SMB_Directory_Access_Test.sql
 Author      : Bruno de Melo Martins
 Description : 
     This script iterates over a list of SMB paths and tests access to each one using
     the Windows 'dir' command via xp_cmdshell. It prints the result for each path,
     allowing you to quickly identify which directories are accessible for backup use.

     This is useful for environments where multiple backup targets exist and you want 
     to validate connectivity or permissions before running a backup job.

 Notes:
     - xp_cmdshell must be enabled temporarily.
     - This script does not perform any backup.
     - Paths are anonymized with fake IPs for public sharing.
*******************************************************************************************/

-- Habilita xp_cmdshell temporariamente (se necessário)
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'xp_cmdshell', 1;
RECONFIGURE;

-- Teste de leitura via DIR para cada diretório
DECLARE @paths TABLE (Path NVARCHAR(500));
INSERT INTO @paths VALUES
('\\192.168.100.1\backup_share'),
('\\192.168.100.2\backup_share'),
('\\192.168.100.3\backup_share'),
('\\192.168.100.4\backup_share'),
('\\192.168.100.5\backup_share'),
('\\192.168.100.6\backup_share'),
('\\192.168.100.7\backup_share'),
('\\192.168.100.8\backup_share'),
('\\192.168.100.9\backup_share'),
('\\192.168.100.10\backup_share'),
('\\192.168.100.11\backup_share'),
('\\192.168.100.12\backup_share'),
('\\192.168.100.13\backup_share'),
('\\192.168.100.14\backup_share'),
('\\192.168.100.15\backup_share'),
('\\192.168.100.16\backup_share'),
('\\192.168.100.17\backup_share');

DECLARE @path NVARCHAR(500), @cmd NVARCHAR(1000);

DECLARE path_cursor CURSOR FOR SELECT Path FROM @paths;
OPEN path_cursor;

FETCH NEXT FROM path_cursor INTO @path;
WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT 'Testing access to: ' + @path;
    SET @cmd = 'dir "' + @path + '"';
    EXEC xp_cmdshell @cmd;

    FETCH NEXT FROM path_cursor INTO @path;
END

CLOSE path_cursor;
DEALLOCATE path_cursor;

-- Reversão (opcional, se quiser desabilitar xp_cmdshell depois)
EXEC sp_configure 'xp_cmdshell', 0;
RECONFIGURE;
EXEC sp_configure 'show advanced options', 0;
RECONFIGURE;
