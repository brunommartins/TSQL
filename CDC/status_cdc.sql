USE XXXX;
GO

DECLARE 
    @start_time      datetime,
    @end_time        datetime,
    @last1           datetime,
    @last2           datetime,
    @backlog1        int,
    @backlog2        int,
    @elapsed_minutes decimal(10,2),
    @processed_backlog int,
    @speed           decimal(10,2),
    @eta_minutes     decimal(10,2);

-- 1) Medida inicial
SET @start_time = GETDATE();

SELECT @last1 = MAX(tran_end_time)
FROM cdc.lsn_time_mapping;

SET @backlog1 = DATEDIFF(MINUTE, @last1, @start_time);

PRINT 'Início da medição: ' + CONVERT(varchar(23), @start_time, 121);
PRINT 'Última tran CDC:   ' + CONVERT(varchar(23), @last1, 121);
PRINT 'Backlog inicial:   ' + CAST(@backlog1 AS varchar(10)) + ' minutos';
PRINT '----------------------------------------------------------';

-- 2) Espera 5 minutos (ajuste se quiser outra janela)
WAITFOR DELAY '00:05:00';

-- 3) Medida final
SET @end_time = GETDATE();

SELECT @last2 = MAX(tran_end_time)
FROM cdc.lsn_time_mapping;

SET @backlog2 = DATEDIFF(MINUTE, @last2, @end_time);

SET @elapsed_minutes = DATEDIFF(SECOND, @start_time, @end_time) / 60.0;
SET @processed_backlog = @backlog1 - @backlog2;

IF @processed_backlog <= 0
BEGIN
    PRINT 'O backlog não diminuiu (ou aumentou) na janela de medição.';
    SELECT 
        @last1           AS Ultima_tran_CDC_inicio,
        @last2           AS Ultima_tran_CDC_fim,
        @backlog1        AS Backlog_Minutos_inicio,
        @backlog2        AS Backlog_Minutos_fim,
        @elapsed_minutes AS Janela_Medicao_Minutos,
        @processed_backlog AS Backlog_reduzido_Minutos,
        NULL AS Minutos_transacao_por_minuto_real,
        NULL AS ETA_Minutos,
        NULL AS ETA_Horario;
    RETURN;
END

SET @speed = @processed_backlog / NULLIF(@elapsed_minutes, 0);  -- min de transação / min real
SET @eta_minutes = @backlog2 / NULLIF(@speed, 0);

SELECT
    @last1            AS Ultima_tran_CDC_inicio,
    @last2            AS Ultima_tran_CDC_fim,
    @backlog1         AS Backlog_Minutos_inicio,
    @backlog2         AS Backlog_Minutos_fim,
    @elapsed_minutes  AS Janela_Medicao_Minutos,
    @processed_backlog AS Backlog_reduzido_Minutos,
    @speed            AS Minutos_transacao_por_minuto_real,
    @eta_minutes      AS ETA_Minutos,
    DATEADD(MINUTE, @eta_minutes, @end_time) AS ETA_Horario;
GO
