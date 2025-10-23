
-- >>> PERSONALIZE AQUI <<<
DECLARE @NEW_SERVER_NAME sysname     = N'<NOVO_SERVIDOR>';           -- Ex.: N'SRV-NEW-01'
DECLARE @DOMAIN          sysname     = N'<seu-dominio.example>';     -- Ex.: N'corp.local'
DECLARE @SITE_A_PREFIX   nvarchar(8) = N'<SITE_A_%>';                -- Ex.: N'DC1_%'  (para blocos IF)
DECLARE @SITE_B_PREFIX   nvarchar(8) = N'<SITE_B_%>';                -- Ex.: N'DC2_%'  (para blocos IF)
-- <<< PERSONALIZE ACIMA >>>

DECLARE @CURRENT_SERVER sysname = @@SERVERNAME;
DECLARE @OTHER_SERVER   sysname;

-- Escolhe uma réplica (qualquer) diferente do servidor atual
SELECT TOP (1) @OTHER_SERVER = replica_server_name
FROM sys.availability_replicas
WHERE replica_server_name <> @@SERVERNAME
ORDER BY replica_server_name;

-- 1) ADD REPLICA no novo servidor (para ser executado nos nós do SITE A)
SELECT
    '
IF (@@SERVERNAME LIKE ''' + @SITE_A_PREFIX + ''')
BEGIN
    ALTER AVAILABILITY GROUP [' + QUOTENAME(name) + N']
    ADD REPLICA ON N''' + @NEW_SERVER_NAME + N''' WITH (
          ENDPOINT_URL = N''TCP://' + @NEW_SERVER_NAME + N'.' + @DOMAIN + N':5022''
        , FAILOVER_MODE = MANUAL
        , AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT
        , BACKUP_PRIORITY = 50
        , SECONDARY_ROLE (ALLOW_CONNECTIONS = ALL)
    );
END' AS t_sql_add_replica_siteA
FROM sys.availability_groups
ORDER BY name ASC;

-- 2) JOIN no nó do SITE B (quando o novo servidor já tiver o RESTORE com NORECOVERY)
SELECT
    '
IF (@@SERVERNAME LIKE ''' + @SITE_B_PREFIX + ''')
BEGIN
    ALTER AVAILABILITY GROUP [' + QUOTENAME(name) + N'] JOIN;
END' AS t_sql_join_siteB
FROM sys.availability_groups
ORDER BY name ASC;

-- 3) JOIN dos bancos ao AG no SITE B
SELECT
    '
IF (@@SERVERNAME LIKE ''' + @SITE_B_PREFIX + ''')
BEGIN
    ALTER DATABASE ' + QUOTENAME(DB_NAME(drs.database_id)) + N'
    SET HADR AVAILABILITY GROUP = ' + QUOTENAME(ag.name) + N';
END' AS t_sql_join_db_siteB
FROM sys.availability_groups ag
JOIN sys.dm_hadr_availability_group_states ags
  ON ags.group_id = ag.group_id
JOIN sys.dm_hadr_database_replica_states drs
  ON drs.group_id = ag.group_id
JOIN sys.dm_hadr_availability_replica_cluster_states rcs
  ON rcs.replica_id = drs.replica_id
JOIN sys.dm_hadr_availability_replica_states ars
  ON ars.group_id = ag.group_id
 AND drs.replica_id = ars.replica_id
WHERE rcs.replica_server_name = @@SERVERNAME
ORDER BY ag.name ASC;

-- 4) Configura READ_ONLY_ROUTING_URL para o NOVO servidor (executar no SITE A)
SELECT
    '
IF (@@SERVERNAME LIKE ''' + @SITE_A_PREFIX + ''')
BEGIN
    ALTER AVAILABILITY GROUP [' + QUOTENAME(name) + N']
    MODIFY REPLICA ON N''' + @NEW_SERVER_NAME + N'''
    WITH (SECONDARY_ROLE (READ_ONLY_ROUTING_URL = N''TCP://' + @NEW_SERVER_NAME + N'.' + @DOMAIN + N':1433''));
END' AS t_sql_set_roru_new_server
FROM sys.availability_groups
ORDER BY name ASC;

-- 5) Define a READ_ONLY_ROUTING_LIST nos primários conhecidos (atual e "outra" réplica)
SELECT
    '
IF (@@SERVERNAME LIKE ''' + @SITE_A_PREFIX + ''')
BEGIN
    -- Primary atual
    ALTER AVAILABILITY GROUP [' + QUOTENAME(name) + N']
    MODIFY REPLICA ON N''' + @CURRENT_SERVER + N'''
    WITH (PRIMARY_ROLE (READ_ONLY_ROUTING_LIST = (N''' + @NEW_SERVER_NAME + N''')));

    -- Outra réplica (se existir)
    ' +
    CASE WHEN @OTHER_SERVER IS NOT NULL THEN
        'ALTER AVAILABILITY GROUP [' + QUOTENAME(name) + N']
         MODIFY REPLICA ON N''' + @OTHER_SERVER + N'''
         WITH (PRIMARY_ROLE (READ_ONLY_ROUTING_LIST = (N''' + @NEW_SERVER_NAME + N''')));'
     ELSE
        '-- (Nenhuma outra réplica encontrada diferente do servidor atual)'
     END + '
END' AS t_sql_set_rorl_on_primaries
FROM sys.availability_groups
ORDER BY name ASC;
