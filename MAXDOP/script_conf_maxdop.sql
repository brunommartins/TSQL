-- Habilita opções avançadas temporariamente
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;

-- Variáveis
DECLARE 
    @cpu_count INT,
    @numa_nodes INT,
    @cpus_por_numa INT,
    @sugestao_maxdop INT,
    @atual_maxdop INT,
    @atual_cost_threshold INT,
    @sugestao_cost_threshold INT = 25;

-- Coleta informações de hardware
SELECT 
    @cpu_count = cpu_count,
    @numa_nodes = numa_node_count
FROM sys.dm_os_sys_info;

-- Calcula CPUs por NUMA
SET @cpus_por_numa = @cpu_count / @numa_nodes;

-- Sugestão para MAXDOP com base em boas práticas
IF @cpu_count <= 8
    SET @sugestao_maxdop = @cpu_count;
ELSE
    SET @sugestao_maxdop = 
        CASE 
            WHEN @cpus_por_numa <= 8 THEN @cpus_por_numa 
            ELSE 8 
        END;

-- Valores atuais
SELECT 
    @atual_maxdop = CAST(value_in_use AS INT)
FROM sys.configurations
WHERE name = 'max degree of parallelism';

SELECT 
    @atual_cost_threshold = CAST(value_in_use AS INT)
FROM sys.configurations
WHERE name = 'cost threshold for parallelism';

-- Diagnóstico
PRINT '--- Diagnóstico do ambiente ---';
PRINT 'CPUs totais: ' + CAST(@cpu_count AS VARCHAR);
PRINT 'NUMA nodes: ' + CAST(@numa_nodes AS VARCHAR);
PRINT 'CPUs por NUMA: ' + CAST(@cpus_por_numa AS VARCHAR);
PRINT 'MaxDOP atual: ' + CAST(@atual_maxdop AS VARCHAR);
PRINT 'Cost Threshold atual: ' + CAST(@atual_cost_threshold AS VARCHAR);

-- Sugestões
PRINT '--- Sugestões com base em boas práticas ---';
PRINT 'MaxDOP sugerido: ' + CAST(@sugestao_maxdop AS VARCHAR);
PRINT 'Cost Threshold sugerido: ' + CAST(@sugestao_cost_threshold AS VARCHAR);

-- Gera comandos
PRINT '--- Comandos sugeridos para aplicar as configurações ---';
PRINT 'EXEC sp_configure ''show advanced options'', 1; RECONFIGURE;';
PRINT 'EXEC sp_configure ''max degree of parallelism'', ' + CAST(@sugestao_maxdop AS VARCHAR) + '; RECONFIGURE;';
PRINT 'EXEC sp_configure ''cost threshold for parallelism'', ' + CAST(@sugestao_cost_threshold AS VARCHAR) + '; RECONFIGURE;';
PRINT 'EXEC sp_configure ''show advanced options'', 0; RECONFIGURE;';
