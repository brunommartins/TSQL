
--lista o número de vlfs

WITH [DatabaseCount] AS(
SELECT 
DB_ID(dbs.[name]) AS DatabaseID,
dbs.[name] AS [Database Name], 
CONVERT(DECIMAL(18,2), dopc1.cntr_value/1024.0) AS [Log Size (MB)]
FROM sys.databases AS dbs WITH (NOLOCK)
INNER JOIN sys.dm_os_performance_counters AS dopc  WITH (NOLOCK) ON dbs.name = dopc.instance_name
INNER JOIN sys.dm_os_performance_counters AS dopc1 WITH (NOLOCK) ON dbs.name = dopc1.instance_name
WHERE dopc.counter_name LIKE N'Log File(s) Used Size (KB)%' 
AND dopc1.counter_name LIKE N'Log File(s) Size (KB)%'
AND dopc1.cntr_value > 0 
)
SELECT [Database Name], [Log Size (MB)],COUNT(b.database_id) AS [Number of VLFS] 
FROM [DatabaseCount] AS [DBCount]  
CROSS APPLY sys.dm_db_log_info([DBCount].DatabaseID) b
 --where [Database Name] = 'dbname'
GROUP BY [Database Name], [Log Size (MB)]





USE [dbname]; -- alterar o nome da base de dados

SELECT name, (size*8)/1024 AS log_MB FROM [dbname].dbo.sysfiles WHERE (64 & status) = 64


DBCC SHRINKFILE (N'dbname_log', 1, TRUNCATEONLY); -- colocar o nome do arquivo lógico ldf
checkpoint


--Executar o job de backup de log
-- Shrink
DBCC SHRINKFILE (N'dbname_log', 1); -- colocar o nome do arquivo lógico ldf
checkpoint
--Executar o job de backup de log
-- pode ser necessário exectar este processo várias vezes até chegar no tamanho mínimo do arquivo.


/*
declare @cleanupHours int = (case when DATEPART(HOUR, getdate()) between 12 and 14 then 336 else null end);
EXECUTE db_Dba.dbo.DatabaseBackup
@Databases = 'dbname',  --alterar o nome da base de dados
@Directory = '\\servidor-BKP\backup',
@MirrorDirectory = '\\servidor-BKP\backup',
@BackupType = 'LOG',
@DatabasesInParallel = 'Y',
@Compress='Y',
@CleanupTime = @cleanupHours,
@CleanupMode = 'AFTER_BACKUP',
@MirrorCleanupTime = @cleanupHours,
@MirrorCleanupMode = 'AFTER_BACKUP',
@LogToTable = 'Y';

*/

--segue a relação de comandos para crescer o arquivos LDF controlando o VLFs, coloque até o tamanho que ache necessário.
--alterar o nome da base de dados e alterar o nome do aquivo lógico da LDF.

ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 8192MB , FILEGROWTH = 1024MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 16384MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 24576MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 32768MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 40960MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 49152MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 57344MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 65536MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 73728MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 81920MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 90112MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 98304MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 106496MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 114688MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 122880MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 131072MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 139264MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 147456MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 155648MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 163840MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 172032MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 180224MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 188416MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 196608MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 204800MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 212992MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 221184MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 229376MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 237568MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 245760MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 253952MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 262144MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 270336MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 278528MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 286720MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 294912MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 303104MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 311296MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 319488MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 327680MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 335872MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 344064MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 352256MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 360448MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 368640MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 376832MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 385024MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 393216MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 401408MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 409600MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 417792MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 425984MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 434176MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 442368MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 450560MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 458752MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 466944MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 475136MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 483328MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 491520MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 499712MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 507904MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 516096MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 524288MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 532480MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 540672MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 548864MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 557056MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 565248MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 573440MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 581632MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 589824MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 598016MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 606208MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 614400MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 622592MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 630784MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 638976MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 647168MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 655360MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 663552MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 671744MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 679936MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 688128MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 696320MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 704512MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 712704MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 720896MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 729088MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 737280MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 745472MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 753664MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 761856MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 770048MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 778240MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 786432MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 794624MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 802816MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 811008MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 819200MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 827392MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 835584MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 843776MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 851968MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 860160MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 868352MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 876544MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 884736MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 892928MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 901120MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 909312MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 917504MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 925696MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 933888MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 942080MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 950272MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 958464MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 966656MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 974848MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 983040MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 991232MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 999424MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1007616MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1015808MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1024000MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1032192MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1040384MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1048576MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1056768MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1064960MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1073152MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1081344MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1089536MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1097728MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1105920MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1114112MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1122304MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1130496MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1138688MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1146880MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1155072MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1163264MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1171456MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1179648MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1187840MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1196032MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1204224MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1212416MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1220608MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1228800MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1236992MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1245184MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1253376MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1261568MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1269760MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1277952MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1286144MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1294336MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1302528MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1310720MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1318912MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1327104MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1335296MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1343488MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1351680MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1359872MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1368064MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1376256MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1384448MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1392640MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1400832MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1409024MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1417216MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1425408MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1433600MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1441792MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1449984MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1458176MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1466368MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1474560MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1482752MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1490944MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1499136MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1507328MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1515520MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1523712MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1531904MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1540096MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1548288MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1556480MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1564672MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1572864MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1581056MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1589248MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1597440MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1605632MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1613824MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1622016MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1630208MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1638400MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1646592MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1654784MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1662976MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1671168MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1679360MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1687552MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1695744MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1703936MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1712128MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1720320MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1728512MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1736704MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1744896MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1753088MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1761280MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1769472MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1777664MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1785856MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1794048MB );
ALTER DATABASE [dbname] MODIFY FILE ( NAME = N'dbname_log', SIZE = 1802240MB );
