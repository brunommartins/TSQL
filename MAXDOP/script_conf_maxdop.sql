
/*
-------------------------------------------------------------------------------------
  Script: Diagnóstico e Sugestão de MAXDOP e Cost Threshold
  Autor: Bruno de Melo Martins
  Versão: 1.0
  Data: 2025-04-18

  Descrição:
  Este script coleta informações de CPU e NUMA do ambiente SQL Server, recomenda 
  valores para as configurações 'max degree of parallelism' e 
  'cost threshold for parallelism' com base em boas práticas da Microsoft.

  Observação:
  O script preserva o valor original da opção 'show advanced options', restaurando
  ao final o estado inicial.

-------------------------------------------------------------------------------------

--- Diagnóstico do ambiente ---
CPUs totais: 32
NUMA nodes: 2
CPUs por NUMA: 16
MaxDOP atual: 0
Cost Threshold atual: 5
--- Sugestões com base em boas práticas ---
MaxDOP sugerido: 8
Cost Threshold sugerido: 25
--- Comandos sugeridos para aplicar as configurações ---
EXEC sp_configure 'show advanced options', 1; RECONFIGURE;
EXEC sp_configure 'max degree of parallelism', 8; RECONFIGURE;
EXEC sp_configure 'cost threshold for parallelism', 25; RECONFIGURE;
EXEC sp_configure 'show advanced options', 0; RECONFIGURE;

*/

-- Armazena valor atual de 'show advanced options'
DECLARE @showAdvancedOriginal INT;

SELECT @showAdvancedOriginal = CAST(value_in_use AS INT)
FROM sys.configurations
WHERE name = 'show advanced options';

-- Ativa temporariamente se necessário
IF @showAdvancedOriginal = 0
BEGIN
    EXEC sp_configure 'show advanced options', 1;
    RECONFIGURE;
END;

-- Variáveis principais
DECLARE 
    @cpu_count INT,
    @numa_nodes INT,
    @cpus_por_numa INT,
    @sugestao_maxdop INT,
    @atual_maxdop INT,
    @atual_cost_threshold INT,
    @sugestao_cost_threshold INT = 25;

-- Coleta informações do sistema
SELECT 
    @cpu_count = cpu_count,
    @numa_nodes = numa_node_count
FROM sys.dm_os_sys_info;

-- Cálculo CPUs por NUMA
SET @cpus_por_numa = @cpu_count / @numa_nodes;

-- Lógica de sugestão de MAXDOP
IF @cpu_count <= 8
    SET @sugestao_maxdop = @cpu_count;
ELSE
    SET @sugestao_maxdop = 
        CASE 
            WHEN @cpus_por_numa <= 8 THEN @cpus_por_numa 
            ELSE 8 
        END;

-- Coleta valores atuais
SELECT @atual_maxdop = CAST(value_in_use AS INT)
FROM sys.configurations
WHERE name = 'max degree of parallelism';

SELECT @atual_cost_threshold = CAST(value_in_use AS INT)
FROM sys.configurations
WHERE name = 'cost threshold for parallelism';

-- Exibição dos resultados
PRINT '--- Diagnóstico do ambiente ---';
PRINT 'CPUs totais: ' + CAST(@cpu_count AS VARCHAR);
PRINT 'NUMA nodes: ' + CAST(@numa_nodes AS VARCHAR);
PRINT 'CPUs por NUMA: ' + CAST(@cpus_por_numa AS VARCHAR);
PRINT 'MaxDOP atual: ' + CAST(@atual_maxdop AS VARCHAR);
PRINT 'Cost Threshold atual: ' + CAST(@atual_cost_threshold AS VARCHAR);

PRINT '--- Sugestões com base em boas práticas ---';
PRINT 'MaxDOP sugerido: ' + CAST(@sugestao_maxdop AS VARCHAR);
PRINT 'Cost Threshold sugerido: ' + CAST(@sugestao_cost_threshold AS VARCHAR);

PRINT '--- Comandos sugeridos para aplicar as configurações ---';
IF @showAdvancedOriginal = 0
BEGIN
	PRINT 'EXEC sp_configure ''show advanced options'', 1; RECONFIGURE;';
    RECONFIGURE;
END;
PRINT 'EXEC sp_configure ''max degree of parallelism'', ' + CAST(@sugestao_maxdop AS VARCHAR) + '; RECONFIGURE;';
PRINT 'EXEC sp_configure ''cost threshold for parallelism'', ' + CAST(@sugestao_cost_threshold AS VARCHAR) + '; RECONFIGURE;';
-- Restaura valor original de 'show advanced options'
IF @showAdvancedOriginal = 0
BEGIN
    PRINT 'EXEC sp_configure ''show advanced options'', 0; RECONFIGURE;';
END

-- Volta a configuração original
IF @showAdvancedOriginal = 0
BEGIN
    EXEC sp_configure 'show advanced options', 0;
    RECONFIGURE;
END
ELSE
BEGIN
    PRINT '-- show advanced options estava ativado; nenhuma ação necessária.';
END
