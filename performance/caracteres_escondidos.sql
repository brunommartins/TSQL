DECLARE @txt NVARCHAR(MAX) = (
    SELECT coluna 
    FROM tblServer 
    WHERE servername = 'valor'
);

SELECT 
    number AS position,
    SUBSTRING(@txt, number, 1) AS character,
    ASCII(SUBSTRING(@txt, number, 1)) AS ascii_code
FROM master.dbo.spt_values
WHERE type = 'P' AND number BETWEEN 1 AND LEN(@txt)
ORDER BY number;


SELECT 
    s.SQLServiceAcct,
    v.number AS position,
    SUBSTRING(s.coluna, v.number, 1) AS character,
    ASCII(SUBSTRING(s.coluna, v.number, 1)) AS ascii_code
FROM tabela s
CROSS APPLY (
    SELECT number 
    FROM master.dbo.spt_values 
    WHERE type = 'P' AND number <= LEN(s.SQLServiceAcct)
) v
WHERE s.servername = 'valor'
ORDER BY v.number;
