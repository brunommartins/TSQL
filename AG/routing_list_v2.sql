;WITH Replicas AS
(
    SELECT
        ag.name AS ag_name,
        ar.replica_id,
        ar.replica_server_name,
        ar.secondary_role_allow_connections_desc,
        ar.read_only_routing_url
    FROM sys.availability_groups ag
    JOIN sys.availability_replicas ar
        ON ar.group_id = ag.group_id
),
-- Targets for read-only routing: AZ4P replicas that accept read-only connections
EligibleReadOnlyTargets AS
(
    SELECT
        ag_name,
        replica_server_name
    FROM Replicas
    WHERE replica_server_name LIKE 'AZ4P%'
      AND secondary_role_allow_connections_desc IN ('READ_ONLY','ALL')
),
-- Replicas that can be primary: everything that is not AZ4P
PrimaryCapableReplicas AS
(
    SELECT
        ag_name,
        replica_id,
        replica_server_name
    FROM Replicas
    WHERE replica_server_name NOT LIKE 'AZ4P%'
),
RoutingList AS
(
    SELECT
        p.ag_name,
        p.replica_server_name,
        STUFF((
            SELECT N',' + QUOTENAME(t.replica_server_name,'''')
            FROM EligibleReadOnlyTargets t
            WHERE t.ag_name = p.ag_name
            ORDER BY t.replica_server_name
            FOR XML PATH(''), TYPE).value('.','nvarchar(max)')
        ,1,1,N'') AS routing_list
    FROM PrimaryCapableReplicas p
),
MissingRoutingList AS
(
    SELECT
        ag.name AS ag_name,
        ar.replica_server_name
    FROM sys.availability_groups ag
    JOIN sys.availability_replicas ar
        ON ar.group_id = ag.group_id
    LEFT JOIN sys.availability_read_only_routing_lists rl
        ON rl.replica_id = ar.replica_id
    WHERE rl.replica_id IS NULL
      AND ar.replica_server_name NOT LIKE 'AZ4P%'
)
SELECT
    N'-- AG: ' + QUOTENAME(m.ag_name) + N' | Replica (primary-capable): ' + QUOTENAME(m.replica_server_name) + CHAR(10) +
    N'ALTER AVAILABILITY GROUP ' + QUOTENAME(m.ag_name) + CHAR(10) +
    N'MODIFY REPLICA ON N' + QUOTENAME(m.replica_server_name,'''') + CHAR(10) +
    N'WITH (PRIMARY_ROLE(READ_ONLY_ROUTING_LIST = (' +
        CASE
            WHEN ISNULL(rl.routing_list,N'') = N'' THEN N'/* no AZ4P read-only targets found for this AG */'
            ELSE rl.routing_list
        END
    + N')));' + CHAR(10) +
    N'GO' AS generated_script
FROM MissingRoutingList m
LEFT JOIN RoutingList rl
    ON rl.ag_name = m.ag_name
   AND rl.replica_server_name = m.replica_server_name
ORDER BY m.ag_name, m.replica_server_name;
