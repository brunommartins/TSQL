IF OBJECT_ID('tempdb..#RecoveryLog') IS NOT NULL DROP TABLE #RecoveryLog;

CREATE TABLE #RecoveryLog (
    LogDate DATETIME,
    ProcessInfo NVARCHAR(100),
    Text NVARCHAR(MAX)
);

-- Recupera logs atuais e anteriores com a palavra 'xxxxx'
INSERT INTO #RecoveryLog
EXEC xp_readerrorlog 0, 1, N'xxxxx';

INSERT INTO #RecoveryLog
EXEC xp_readerrorlog 1, 1, N'xxxxx';

-- Mostra resultados
SELECT *
FROM #RecoveryLog
WHERE Text LIKE N'%recovery%'
ORDER BY LogDate DESC;
