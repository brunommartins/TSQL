/* Bancos x AGs x Listener x IPs x Réplicas x Nó (compatível SQL 2012+)
   - Sem STRING_AGG (usa STUFF/XML)
   - Sem 'subnet_mask'
   - Nó do cluster via dm_hadr_cluster_members (join por nome do servidor)
*/

SELECT
    ag.name                                AS AvailabilityGroup,
    adc.database_name                      AS DatabaseName,

    -- Listener (DNS:Port)
    (SELECT TOP (1) CONCAT(agl.dns_name, ':', agl.port)
     FROM sys.availability_group_listeners agl
     WHERE agl.group_id = ag.group_id)     AS ListenerDNS_Port,

    -- IPs do listener agregados
    (SELECT STUFF((
        SELECT DISTINCT ' , ' + ip.ip_address
        FROM sys.availability_group_listeners agl2
        JOIN sys.availability_group_listener_ip_addresses ip
             ON ip.listener_id = agl2.listener_id
        WHERE agl2.group_id = ag.group_id
        FOR XML PATH(''), TYPE
    ).value('.','nvarchar(max)'),1,3,''))  AS ListenerIPs,

    r.replica_server_name                  AS ReplicaInstance,

    -- Nó do cluster (mapeado pelo nome do servidor)
    cm.member_name                         AS ClusterNode,

    CASE WHEN ags.primary_replica = r.replica_server_name
         THEN 'PRIMARY' ELSE 'SECONDARY' END AS ReplicaRole,

    r.availability_mode_desc               AS AvailabilityMode,
    r.failover_mode_desc                   AS FailoverMode,
    r.secondary_role_allow_connections_desc AS ReadableSecondary,
    r.seeding_mode_desc                    AS SeedingMode,
    r.endpoint_url                         AS EndpointURL
FROM sys.availability_groups ag
JOIN sys.availability_databases_cluster adc
  ON adc.group_id = ag.group_id
JOIN sys.availability_replicas r
  ON r.group_id = ag.group_id
LEFT JOIN sys.dm_hadr_availability_group_states ags
  ON ags.group_id = ag.group_id
LEFT JOIN sys.dm_hadr_cluster_members cm
  ON cm.member_name = r.replica_server_name
-- Opcional: apenas bancos de usuário
 WHERE adc.database_name IN ('PositivoPayments')
ORDER BY
    ag.name,
    adc.database_name,
    CASE WHEN ags.primary_replica = r.replica_server_name THEN 0 ELSE 1 END,
    r.replica_server_name;
