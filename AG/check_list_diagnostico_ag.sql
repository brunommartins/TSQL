/*
O que esse script cobre:
Item	Verificação
1	Status da base no AG (sincronização, suspensão, etc)
2	Estado da réplica local (primária/secundária, conectada?)
3	Status do endpoint HADR
4	Últimos erros de AG no Error Log
5	Verifica se está SUSPENDED e sugere RESUME
6	Verifica se a base está realmente associada ao AG no cluster
*/


-- ================================
-- CHECKLIST DIAGNÓSTICO AG
-- ================================

-- 1. Verifica o status da base no AG
PRINT '--- 1. STATUS DO DATABASE NO AG ---';
SELECT 
    d.name AS database_name,
    drs.database_id,
    drs.is_suspended,
    drs.synchronization_state_desc,
    drs.database_state_desc,
    drs.suspend_reason_desc,
    drs.last_hardened_time
FROM sys.dm_hadr_database_replica_states drs
JOIN sys.databases d ON d.database_id = drs.database_id
WHERE d.name = 'DBPIMSGPRO_OPE';

-- 2. Verifica se a réplica atual está como primária ou secundária
PRINT '--- 2. RÉPLICA ATUAL ---';
SELECT 
    ar.replica_server_name,
    ars.role_desc,
    ars.operational_state_desc,
    ars.connected_state_desc
FROM sys.dm_hadr_availability_replica_states ars
JOIN sys.availability_replicas ar ON ars.replica_id = ar.replica_id
WHERE ar.replica_server_name = @@SERVERNAME;

-- 3. Verifica status do endpoint de mirror/HADR
PRINT '--- 3. ENDPOINT HADR ---';
SELECT 
    name, 
    state_desc, 
    role_desc, 
    connection_auth_desc
FROM sys.database_mirroring_endpoints;

-- 4. Verifica se há falhas recentes de conexão no AG
PRINT '--- 4. ÚLTIMAS FALHAS NO LOG ---';
EXEC xp_readerrorlog 0, 1, N'Availability', NULL, NULL, NULL, N'DESC';

-- 5. Verifica se a base está suspensa e sugere comando para RESUME
PRINT '--- 5. VERIFICAÇÃO DE SUSPENSÃO ---';
IF EXISTS (
    SELECT 1
    FROM sys.dm_hadr_database_replica_states drs
    JOIN sys.databases d ON d.database_id = drs.database_id
    WHERE d.name = 'dbname'
      AND drs.is_suspended = 1
)
BEGIN
    DECLARE @sql NVARCHAR(500) = 'ALTER DATABASE [DBPIMSGPRO_OPE] SET HADR RESUME';
    PRINT '⚠️  A base está suspensa. Comando sugerido:';
    PRINT @sql;
END
ELSE
BEGIN
    PRINT '✅ A base não está suspensa.';
END

-- 6. Verifica se o banco está realmente conectado ao AG
PRINT '--- 6. CHECK JOIN NO CLUSTER ---';
SELECT 
    d.name AS database_name,
    d.state_desc AS db_state,
    cs.is_database_joined
FROM sys.databases d
JOIN sys.dm_hadr_database_replica_states drs ON d.database_id = drs.database_id
JOIN sys.dm_hadr_database_replica_cluster_states cs ON drs.group_database_id = cs.group_database_id
WHERE d.name = 'dbname';
