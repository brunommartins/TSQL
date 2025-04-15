USE YourDatabaseName;
SET NOCOUNT ON;
SET XACT_ABORT ON;

-- =====================================================================
-- Script: Daily Data Cleanup Job (Supports Multiple Schemas)
-- Author: brunommartins@gmail.com
-- Description:
--     This script deletes historical records older than 2 years from
--     a configurable list of tables and columns. It supports simulation,
--     email notification, and schema-aware logic.
--
-- Features:
--   - Deletes data older than 730 days based on datetime columns
--   - Handles multiple tables and schemas dynamically
--   - Sends email report with deleted row counts
--   - Supports simulation mode (no DELETEs)
--
-- Required Setup:
--   - Database Mail must be configured
--   - Update @ProfileName and @Recipient as needed
-- =====================================================================

DECLARE @cutoffDate DATETIME = DATEADD(DAY, DATEDIFF(DAY, 0, GETDATE()) - 730, 0);
DECLARE @SQL NVARCHAR(MAX);
DECLARE @SchemaName SYSNAME, @TableName SYSNAME, @ColumnName SYSNAME;

DECLARE @EmailBody NVARCHAR(MAX) = 
    'Data cleanup job executed on ' + CONVERT(VARCHAR, GETDATE(), 120) + CHAR(13) + CHAR(13);

DECLARE @ProfileName SYSNAME = 'YourMailProfile'; --  Replace with your mail profile
DECLARE @Recipient NVARCHAR(200) = 'your.email@domain.com'; --  Replace with actual recipients
DECLARE @Simulate BIT = 0; -- Set to 1 to simulate without deleting

IF @Simulate = 1
    SET @EmailBody += '[SIMULATION MODE ENABLED - No data was deleted]' + CHAR(13) + CHAR(13);

-- List of tables to clean: schema, table, column
DECLARE @PurgeList TABLE (
    SchemaName SYSNAME,
    TableName SYSNAME,
    ColumnName SYSNAME
);

--  Add your target tables and columns here
INSERT INTO @PurgeList (SchemaName, TableName, ColumnName)
VALUES
    ('your_schema', 'your_table', 'your_datetime_column');

-- Create result table
IF OBJECT_ID('tempdb..##EmailReport') IS NOT NULL DROP TABLE ##EmailReport;
CREATE TABLE ##EmailReport (
    TableName SYSNAME,
    RowCount INT
);

-- Cursor to loop through list
DECLARE purge_cursor CURSOR FOR
SELECT SchemaName, TableName, ColumnName FROM @PurgeList;

OPEN purge_cursor;
FETCH NEXT FROM purge_cursor INTO @SchemaName, @TableName, @ColumnName;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM INFORMATION_SCHEMA.TABLES 
        WHERE TABLE_SCHEMA = @SchemaName AND TABLE_NAME = @TableName
    )
    BEGIN
        IF @Simulate = 1
        BEGIN
            SET @SQL = '
            DECLARE @rows INT;
            SELECT @rows = COUNT(*) 
            FROM [' + @SchemaName + '].[' + @TableName + ']
            WHERE [' + @ColumnName + '] < @cutoffDate;
            INSERT INTO ##EmailReport (TableName, RowCount)
            VALUES (''' + @SchemaName + '.' + @TableName + ''', @rows);';
        END
        ELSE
        BEGIN
            SET @SQL = '
            DECLARE @rows INT;
            DELETE FROM [' + @SchemaName + '].[' + @TableName + ']
            WHERE [' + @ColumnName + '] < @cutoffDate;
            SET @rows = @@ROWCOUNT;
            INSERT INTO ##EmailReport (TableName, RowCount)
            VALUES (''' + @SchemaName + '.' + @TableName + ''', @rows);';
        END

        EXEC sp_executesql @SQL, N'@cutoffDate DATETIME', @cutoffDate = @cutoffDate;
    END
    ELSE
    BEGIN
        SET @EmailBody += 'Table not found: ' + @SchemaName + '.' + @TableName + CHAR(13);
    END

    FETCH NEXT FROM purge_cursor INTO @SchemaName, @TableName, @ColumnName;
END

CLOSE purge_cursor;
DEALLOCATE purge_cursor;

-- Build email body
DECLARE @line NVARCHAR(500);
DECLARE result_cursor CURSOR FOR
    SELECT TableName + ': ' + CAST(ISNULL(RowCount, 0) AS VARCHAR) + ' rows deleted'
    FROM ##EmailReport;

OPEN result_cursor;
FETCH NEXT FROM result_cursor INTO @line;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @EmailBody += @line + CHAR(13);
    FETCH NEXT FROM result_cursor INTO @line;
END

CLOSE result_cursor;
DEALLOCATE result_cursor;

-- Send summary email
EXEC msdb.dbo.sp_send_dbmail
    @profile_name = @ProfileName,
    @recipients = @Recipient,
    @subject = 'Data Cleanup Report',
    @body = @EmailBody;

-- Clean up
DROP TABLE ##EmailReport;
