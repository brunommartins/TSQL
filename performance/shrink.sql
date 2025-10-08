SELECT
CAST(sysfiles.size/128.0 AS int) AS File_Size_inMBs,
sysfiles.name AS File_Logical_Name,
sysfiles.filename AS File_Name_And_Location,
CONVERT(sysname,DatabasePropertyEx('TempDB','Status')) AS [Status],
CONVERT(sysname,DatabasePropertyEx('TempDB','Updateability')) AS Usage,
CONVERT(sysname,DatabasePropertyEx('TempDB','Recovery')) AS Recovery_Mode,
CAST(sysfiles.size/128.0 - CAST(FILEPROPERTY(sysfiles.name,  + '' +
       'SpaceUsed' + '' + '' ) AS int)/128.0 AS int) AS Free_Space_inMBs,
CAST(100 * (CAST (((sysfiles.size/128.0 -CAST(FILEPROPERTY(sysfiles.name,
 + '' + 'SpaceUsed' + '' + '' ) AS int)/128.0)/(sysfiles.size/128.0))
AS decimal(4,2))) AS varchar(8)) + '' + '' + '%' + '' + '' AS 'Free_Space_Percentage'
FROM dbo.sysfiles


DECLARE @File VarChar(100)
                DECLARE @Inicial INT 
                DECLARE @Final int 

                SET @File = 'Nome_do_arquivo'			-- Nome do arquivo de dados ou de log, sem a extensÃ£o (.mdf, .ndf ou .ldf)
                SET @Inicial = XXX_valor_inicial		-- Tamanho inicial do arquivo que mostra na tela de shrink
                SET @Final = XXX_valor_final			-- Tamanho final de objetivo a compactar

                WHILE @Inicial > @Final
                BEGIN
                    dbcc shrinkfile(@File, @Inicial)
                    PRINT CAST(@Inicial as VarChar(20)) + ' - ' + Convert(VarChar(30), Getdate(), 120)
                    SET @Inicial = @Inicial - 100		-- Quantidade de compactação por vez. Neste caso, está a cada 100MBs
                END
                GO
