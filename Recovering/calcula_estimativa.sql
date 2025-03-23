-- Primeira medição
DECLARE @valor1 BIGINT, @valor2 BIGINT, @diferenca BIGINT;
DECLARE @taxaKBps DECIMAL(10,2), @tempoEstimadoSeg DECIMAL(10,2);
DECLARE @tempoEstimadoMin DECIMAL(10,2), @tempoEstimadoHoras DECIMAL(10,2);
DECLARE @horaAtual DATETIME = GETDATE(), @horaFinal DATETIME;

-- Coleta valor inicial
SELECT @valor1 = cntr_value
FROM sys.dm_os_performance_counters
WHERE [object_name] LIKE '%Database Replica%'
  AND [counter_name] = 'Log remaining for undo'
  AND instance_name = 'xxxxxx';  -- Substitua conforme o nome correto

-- Aguarda 30 segundos
WAITFOR DELAY '00:00:30';

-- Coleta valor novamente
SELECT @valor2 = cntr_value
FROM sys.dm_os_performance_counters
WHERE [object_name] LIKE '%Database Replica%'
  AND [counter_name] = 'Log remaining for undo'
  AND instance_name = 'xxxxxx';

-- Cálculo da diferença e taxa
SET @diferenca = @valor1 - @valor2;

IF @diferenca > 0
BEGIN
    SET @taxaKBps = @diferenca / 30.0;                    -- KB/s
    SET @tempoEstimadoSeg = @valor2 / @taxaKBps;          -- Segundos restantes
    SET @tempoEstimadoMin = @tempoEstimadoSeg / 60.0;
    SET @tempoEstimadoHoras = @tempoEstimadoMin / 60.0;
    SET @horaFinal = DATEADD(SECOND, @tempoEstimadoSeg, @horaAtual);

    PRINT 'Taxa de processamento: ' + CAST(@taxaKBps AS VARCHAR) + ' KB/s';
    PRINT 'Tempo estimado restante:';
    PRINT '  - ' + CAST(@tempoEstimadoSeg AS VARCHAR) + ' segundos';
    PRINT '  - ' + CAST(@tempoEstimadoMin AS VARCHAR) + ' minutos';
    PRINT '  - ' + CAST(@tempoEstimadoHoras AS VARCHAR) + ' horas';
    PRINT 'Hora atual: ' + CONVERT(VARCHAR, @horaAtual, 120);
    PRINT 'Hora estimada de conclusão: ' + CONVERT(VARCHAR, @horaFinal, 120);
END
ELSE
BEGIN
    PRINT 'O contador não está diminuindo (sem progresso ou processo concluído)';
END
