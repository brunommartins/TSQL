DECLARE @Senha NVARCHAR(30) = ''
DECLARE @Maiusculas NVARCHAR(50) = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
DECLARE @Minusculas NVARCHAR(50) = 'abcdefghijklmnopqrstuvwxyz'
DECLARE @Numeros NVARCHAR(20)    = '0123456789'
DECLARE @Especiais NVARCHAR(30)  = '!@#$%^&*()-_=+[]{}|;:,.<>?'
DECLARE @Todos NVARCHAR(200) = @Maiusculas + @Minusculas + @Numeros + @Especiais

-- Garantir pelo menos 1 de cada tipo
SET @Senha = 
    SUBSTRING(@Maiusculas, CAST(RAND(CHECKSUM(NEWID())) * LEN(@Maiusculas) + 1 AS INT), 1) +
    SUBSTRING(@Minusculas, CAST(RAND(CHECKSUM(NEWID())) * LEN(@Minusculas) + 1 AS INT), 1) +
    SUBSTRING(@Numeros,    CAST(RAND(CHECKSUM(NEWID())) * LEN(@Numeros) + 1 AS INT), 1) +
    SUBSTRING(@Especiais,  CAST(RAND(CHECKSUM(NEWID())) * LEN(@Especiais) + 1 AS INT), 1)

-- Completar até 30 caracteres com aleatórios de todos os tipos
WHILE LEN(@Senha) < 30
BEGIN
    SET @Senha += SUBSTRING(@Todos, CAST(RAND(CHECKSUM(NEWID())) * LEN(@Todos) + 1 AS INT), 1)
END

-- Embaralhar os caracteres da senha (opcional, mas melhora a aleatoriedade da ordem)
;WITH Tally AS (
    SELECT TOP (30) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects
)
SELECT SenhaGerada = (
    SELECT SUBSTRING(@Senha, n, 1)
    FROM Tally
    ORDER BY NEWID()
    FOR XML PATH(''), TYPE
).value('.', 'NVARCHAR(30)')
