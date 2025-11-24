

/****** Object:  StoredProcedure [SPU].[JOB_Particionamento_Expurgo]    Script Date: 11/24/2025 3:00:17 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE      
PROCEDURE [SPU].[JOB_Particionamento_Expurgo]
@forceWorker INT = 0, -- se 1 sempre worker, independente de primario ou secundario - ideal para jobs de export auxiliares que rodam no primario.
@soSecundario INT = 0 -- se 1 somente worker, e somente se estiver no secundario - ideal para jobs de extras de export que rodam no secundario.
AS
-- Procedure que simplifica o procedimento de manutencao nos jobs.
-- Recomendado manter todas iguais, evitando customizacoes por base ou ambiente, isso facilita a manutencao.
BEGIN
declare @msgerr         varchar(8000) = '',
        @dataFuturo     date,
        @partFuncName   NVARCHAR(50) = (select name from sys.partition_functions WHERE name not like '%[_]V%'),
        @reposArqZip1   NVARCHAR(80),
        @reposArqZip2   NVARCHAR(80),
        @diasaManter    INT,
        @ePrimario      INT=0,
        @pastaTmpNivel1 varchar(70),
        @exec7zip       nvarchar(70);

select @dataFuturo = DATEADD(DAY, DiasCriarFuturo, CONVERT(date, getdate()))
     , @pastaTmpNivel1 = PastaTmpNivel1
     , @exec7zip = Exec7zip
     , @diasaManter = DiasManter
     , @reposArqZip1 = ReposArqZip1+'\'+db_name()+'\'
     , @reposArqZip2 = ReposArqZip2+'\'+db_name()+'\'
from SPU.Parametros_Particionamento_Expurgo
where DatabaseName=db_name();

IF len(coalesce(@pastaTmpNivel1,''))=0
  throw 50000, 'Erro ao obter parametros da tabela SPU.Parametros_Particionamento_Expurgo', 1;

-- Verifica se e replica primaria:
select @ePrimario=count(*) from sys.dm_hadr_availability_replica_states where is_local=1 and role=1 and role_desc='PRIMARY';
if @ePrimario<>0 and @soSecundario<>0
  begin
  print 'Job rodando em replica primaria, chamado com @soSecundario='+cast(@soSecundario as varchar)+': Nada a fazer.';
  return;
  end;

-- verifica se as V_PRIM estao criadas corretamente!
drop table if exists #controlViews;
with viw as (
  select coalesce(ts.name,'null')+'.'+t.name COLLATE Latin1_General_100_CI_AS tabname
       , coalesce(vs.name,'null')+'.'+o.name COLLATE Latin1_General_100_CI_AS viewname
       , trim(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(m.definition,char(9),' '),char(13),' ')
         ,char(10),' '),'[',''),']',''),'    ',' '),'   ',' '),'  ',' '),' GO',''),';','')) COLLATE Latin1_General_100_CI_AS viewtext
  from sys.tables t
  join sys.objects o on o.type = 'V' and o.name='V_PRIM_'+t.name
  left outer join sys.sql_modules m on m.object_id = o.object_id
  left outer join sys.schemas ts on ts.schema_id=t.schema_id
  left outer join sys.schemas vs on vs.schema_id=o.schema_id )
, dns as (
  select c.database_name COLLATE Latin1_General_100_CI_AS dbname
       , l.dns_name+(case when @@SERVICENAME='MSSQLSERVER' then '' else '\'+@@SERVICENAME end) COLLATE Latin1_General_100_CI_AS dnsname
  from sys.availability_group_listeners l
  join sys.availability_databases_cluster c on c.group_id=l.group_id
  where c.database_name=DB_NAME() )
select viw.*, dns.*
into #controlViews
from viw
left outer join dns on viewtext = 'CREATE VIEW '+viewname+' AS SELECT * FROM '+dnsname+'.'+dbname+'.'+tabname
where dnsname is null;
if exists (select 1 from #controlViews)
  begin
  select * from #controlViews;
  throw 50000, 'Erro na criacao de alguma view V_PRIM... verifique a correlacao entre as views e seus respectivos sites primarios!', 1;
  end;

if @ePrimario>0 and coalesce(@forceWorker,0)=0 -- Modo Master: se esta rodando no primario, e sem @forceWorker:
  begin
  begin try
    print convert(varchar, current_timestamp, 121)+'-chamando Pr_Split_Partition';
    exec dbo.Pr_Split_Partition @partFuncName, @dataFuturo;
  end try begin catch
    if (xact_state()) <> 0 rollback;
    set @msgerr=@msgerr+'Erro #'+coalesce(cast(error_number() as varchar),'null')+' (sev='+coalesce(cast(error_severity() as varchar),'null')
               +' state='+coalesce(cast(error_state() as varchar),'null')+' xact_state='+coalesce(cast(xact_state() as varchar),'null')
               +') na procedure '+coalesce(error_procedure(),'null')+' linha '+coalesce(cast(error_line() as varchar),'null')+':'
               +char(13)+char(10)+coalesce(error_message(),'null')+char(13)+char(10)+char(13)+char(10);
  end catch;
  begin try
    print convert(varchar, current_timestamp, 121)+'-chamando DetachPartitionsV2';
    exec SPU.DetachPartitionsV2 @partFuncName, @diasaManter, @reposArqZip1, @reposArqZip2;
  end try begin catch
    if (xact_state()) <> 0 rollback;
    set @msgerr=@msgerr+'Erro #'+coalesce(cast(error_number() as varchar),'null')+' (sev='+coalesce(cast(error_severity() as varchar),'null')
               +' state='+coalesce(cast(error_state() as varchar),'null')+' xact_state='+coalesce(cast(xact_state() as varchar),'null')
               +') na procedure '+coalesce(error_procedure(),'null')+' linha '+coalesce(cast(error_line() as varchar),'null')+':'
               +char(13)+char(10)+coalesce(error_message(),'null')+char(13)+char(10)+char(13)+char(10);
  end catch;
  end;

else -- Modo Worker: se esta rodando no secundario, ou passado @forceWorker<>0
  begin
  begin try
    print convert(varchar, current_timestamp, 121)+'-chamando ExportWorkerV2';
    exec SPU.ExportWorkerV2 @pastaTmpNivel1=@pastaTmpNivel1, @exec7zip=@exec7zip;
  end try begin catch
    if (xact_state()) <> 0 rollback;
    set @msgerr=@msgerr+'Erro #'+coalesce(cast(error_number() as varchar),'null')+' (sev='+coalesce(cast(error_severity() as varchar),'null')
               +' state='+coalesce(cast(error_state() as varchar),'null')+' xact_state='+coalesce(cast(xact_state() as varchar),'null')
               +') na procedure '+coalesce(error_procedure(),'null')+' linha '+coalesce(cast(error_line() as varchar),'null')+':'
               +char(13)+char(10)+coalesce(error_message(),'null')+char(13)+char(10)+char(13)+char(10);
  end catch;
  end;

-- finalizacao, independente de ser master ou worker:
begin try
  print convert(varchar, current_timestamp, 121)+'-chamando DropaTabelasExportadasV2';
  exec SPU.DropaTabelasExportadasV2 @pastaTmpNivel1;
end try
begin catch
  if (xact_state()) <> 0 rollback;
  set @msgerr=@msgerr+'Erro #'+coalesce(cast(error_number() as varchar),'null')+' (sev='+coalesce(cast(error_severity() as varchar),'null')
             +' state='+coalesce(cast(error_state() as varchar),'null')+' xact_state='+coalesce(cast(xact_state() as varchar),'null')
             +') na procedure '+coalesce(error_procedure(),'null')+' linha '+coalesce(cast(error_line() as varchar),'null')+':'
             +char(13)+char(10)+coalesce(error_message(),'null')+char(13)+char(10)+char(13)+char(10);
end catch

-- retorna os erros gerados durante a execucao das procedures acima:
if len(@msgerr)>0
  throw 50000, @msgerr, 1;
print convert(varchar, current_timestamp, 121)+'-FEITO';
end;
GO


