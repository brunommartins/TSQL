SET NOCOUNT ON;

DECLARE @BatchSize INT = 10000;  --Se quiser ainda menos impacto, pode reduzir o @BatchSize (ex: para 5000 ou 1000).
DECLARE @RowsAffected INT = 1;

WHILE @RowsAffected > 0
BEGIN
    BEGIN TRAN;
    #ajustar conforme necessário a sua query
    DELETE TOP (@BatchSize)
    FROM dbname.dbo.nome_tabela
    WHERE NM_SITUACAO = 'Pendente';

    SET @RowsAffected = @@ROWCOUNT;

    COMMIT;

    -- Aguarda 1 segundo entre os lotes (opcional)
    WAITFOR DELAY '00:00:01';
END
