
/****** Object:  StoredProcedure [dbo].[Pr_Split_Partition]    Script Date: 11/24/2025 3:02:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER  
PROCEDURE [dbo].[Pr_Split_Partition]
	@PartitionFunction [nvarchar](500),
	@EndTime [datetime2](3)
WITH EXECUTE AS CALLER
AS
BEGIN
DECLARE @IntervalType INT = 1; --------->> 1 = DAY (DEFAULT), 2 = MONTH
DECLARE @StartDate DATETIME2(3);
DECLARE @dt1 DATETIME = getdate()
DECLARE @dt2 DATETIME
DECLARE @Command NVARCHAR(MAX);
DECLARE @i int = 1;
DECLARE @total int;
DECLARE @cmd_ps NVARCHAR(1500) = '', @rangestr NVARCHAR(500) = '', @jaexiste varchar(8000)='';
DECLARE @name varchar(50), @filegroup varchar(50);

DROP TABLE IF EXISTS #Tb_PsFiles;
with q1 as (
    select distinct ps.name, fg.name filegroup, max(rv.value) data
    FROM sys.partition_functions pf
    JOIN sys.partition_schemes ps ON ps.function_id = pf.function_id
    JOIN sys.indexes i ON i.data_space_id = ps.data_space_id-- and i.type_desc in ('CLUSTERED','HEAP')
    JOIN sys.partitions p ON p.object_id = i.object_id AND p.index_id = i.index_id
    JOIN sys.tables t on t.object_id = p.object_id
    LEFT OUTER JOIN sys.destination_data_spaces dds ON dds.partition_scheme_id = ps.data_space_id AND dds.destination_id = p.partition_number
    LEFT OUTER JOIN sys.filegroups fg ON dds.data_space_id = fg.data_space_id
    LEFT OUTER JOIN sys.partition_range_values rv ON rv.function_id = pf.function_id AND rv.boundary_id = (CASE pf.boundary_value_on_right WHEN 1 THEN p.partition_number-1 ELSE p.partition_number END)
    WHERE pf.name = @PartitionFunction
    and (CASE pf.boundary_value_on_right WHEN 1 THEN p.partition_number-1 ELSE p.partition_number END) > 0 -- elimina o Warning: Null value is eliminated by an aggregate or other SET operation.
    GROUP BY ps.name, fg.name)
, q2 as ( -- este passo e necessario pois pode acontecer de um mesmo PS ter trocado de filegroup, pra pegar o ultimo filegroup de cada PS
    SELECT ROW_NUMBER() OVER(PARTITION BY name ORDER BY data desc) AS RowInt#, name, filegroup, data
    FROM q1 )
select ROW_NUMBER() OVER (ORDER BY filegroup) Row#, name, filegroup, data
into #Tb_PsFiles
from q2 where RowInt#=1;

IF @IntervalType = 1 OR @IntervalType IS NULL
	SET @StartDate=cast(cast(getdate() as date) as datetime2(3));
else 
	SET @StartDate=cast(DATEADD(month, DATEDIFF(month, 0, getdate()), 0) as datetime2(3));

select @total = count(*) from #Tb_PsFiles;
IF @total=0
	BEGIN
		RAISERROR ('Não foi possível localizar a partition function informada',16,1);
		set @dt2 = getdate()
		INSERT INTO  DB_DBA.dbo.CommandLog ([DatabaseName],[ObjectName], [ErrorMessage], [ErrorNumber],[StartTime], [EndTime], [Command],[CommandType])
		values(  DB_NAME(),'Pr_Split_Partition','Não foi possível localizar a partition function informada',16, @dt1,@dt2, @Command,'ALTER PARTITION' );
		RETURN;
	END;

PRINT 'ADICIONANDO PARTIÇÕES À PARTITION FUNCTION ' + @PartitionFunction + ': ';
WHILE ( @i <= @total)
	BEGIN
	select @name= name , @filegroup = filegroup from #Tb_PsFiles where Row# = @i;
    set  @cmd_ps = @cmd_ps + ' ALTER PARTITION SCHEME ' + @name + ' NEXT USED ['+ @filegroup +'] ' + char(13)+CHAR(10);
    SET @i = @i + 1;
	END;
 
WHILE @StartDate < @EndTime
	BEGIN
	IF @IntervalType = 1 OR @IntervalType IS NULL
		SET @StartDate = DATEADD(DD,1,@StartDate);
	else
		SET @StartDate = DATEADD(MM,1,@StartDate);
	SET @rangestr=CAST(YEAR(@StartDate) AS VARCHAR) + '-'
				+ RIGHT('0'+CAST(MONTH(@StartDate) AS VARCHAR),2) + '-'
				+ RIGHT('0'+CAST(DAY(@StartDate) AS VARCHAR),2);
	SET @Command =' ALTER PARTITION FUNCTION ' + @PartitionFunction + '() SPLIT RANGE (''' + @rangestr + ''')' ;
	BEGIN TRY
		IF NOT EXISTS (SELECT 1 FROM sys.partition_range_values v join sys.partition_functions f on f.function_id=v.function_id
					   WHERE f.name=@PartitionFunction and v.value = @StartDate)
			BEGIN
				PRINT 'Criando:'+ @rangestr;
				EXEC sp_executesql @cmd_ps;
                --PRINT '@cmd_ps='+@cmd_ps+' [OK]';
				EXEC sp_executesql @Command;
                --PRINT '@Command='+@Command+' [OK]';
				set @dt2 = getdate();
				INSERT INTO  DB_DBA.dbo.CommandLog ([DatabaseName],[ObjectName], [ErrorNumber],[StartTime], [EndTime], [Command],[CommandType])
				values( DB_name(),'Pr_Split_Partition', 0,@dt1,@dt2, @cmd_ps + @Command,'ALTER PARTITION' )
			END;
		ELSE
			set @jaexiste = @jaexiste + @rangestr + '; ';
	END TRY
	BEGIN CATCH
		set @dt2 = getdate()
		INSERT INTO  DB_DBA.dbo.CommandLog ([DatabaseName],[ObjectName], [ErrorMessage], [ErrorNumber],[StartTime], [EndTime], [Command],[CommandType])
		values(  DB_NAME(),'Pr_Split_Partition',ERROR_MESSAGE(),ERROR_NUMBER(), @dt1,@dt2, @Command,'ALTER PARTITION' );
		THROW;
	END CATCH;
	END;

PRINT 'Já existentes anteriormente:'+ trim(' ;' from @jaexiste);
set @dt2 = getdate()
INSERT INTO  DB_DBA.dbo.CommandLog ([DatabaseName],[ObjectName], [ErrorMessage], [ErrorNumber],[StartTime], [EndTime], [Command],[CommandType])
values(  DB_NAME(),'Pr_Split_Partition','Já existentes anteriormente:'+ trim(' ;' from @jaexiste),16, @dt1,@dt2, @Command,'ALTER PARTITION' );
END;
