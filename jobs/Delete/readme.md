Subject: Explanation – SQL Server Job “Daily Data Cleanup Job”

Hello,

This document explains the purpose and functionality of the SQL Server job named **“Daily Data Cleanup Job.”**  
The job is designed to run daily and automatically remove historical records from selected tables.

Job Summary:
------------
This job deletes records older than **2 years (730 days)** from a configurable list of tables.  
Each table is mapped to a datetime column, which determines the cutoff for deletion.

Job Features:
-------------
- Fully parameterized for table schema, table name, and date column
- Safe and resilient: skips tables that do not exist
- Tracks and reports the number of deleted records per table
- Sends an automated summary via Database Mail after execution
- Includes a **simulation mode** (`@Simulate = 1`) to preview deletions without affecting data

Simulation Mode:
----------------
Simulation mode allows safe preview of the deletion logic.  
When enabled, the script counts the records that would be deleted, but does not perform any actual deletions.  
This is useful for validating table logic before applying changes in production.

Adding New Tables:
------------------
To add new tables to the cleanup process, simply insert new entries in the following format:

```sql
INSERT INTO @PurgeList (SchemaName, TableName, ColumnName)
VALUES ('your_schema', 'your_table', 'your_datetime_column');
