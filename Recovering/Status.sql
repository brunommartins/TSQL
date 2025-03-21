SELECT 
    session_id, 
    command, 
    percent_complete, 
    start_time, 
    estimated_completion_time / 1000 / 60 AS Est_Minutos,
    DATEADD(SECOND, estimated_completion_time / 1000, GETDATE()) AS Est_Conclusao
FROM sys.dm_exec_requests
WHERE command LIKE 'DB%';

session_id command                          percent_complete start_time              Est_Minutos          Est_Conclusao
---------- -------------------------------- ---------------- ----------------------- -------------------- -----------------------
32         DB MIRROR                        0                2025-03-20 23:43:16.840 0                    2025-03-21 07:31:15.787
44         DB STARTUP                       85.29412         2025-03-20 23:43:17.183 4                    2025-03-21 07:36:06.787
106        DB STARTUP                       0                2025-03-20 23:51:02.047 0                    2025-03-21 07:31:15.787
113        DB STARTUP                       0                2025-03-21 06:58:47.970 0                    2025-03-21 07:31:15.787
125        DB STARTUP                       0                2025-03-21 00:02:44.300 0                    2025-03-21 07:31:15.787
