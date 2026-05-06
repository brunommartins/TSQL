/*
    Script: SQLServer_Monitor_Blocking_And_Memory_Grants.sql
    Author: BMaciel Bassani Sparrenberger
    Description:
        Monitora sessões com bloqueio prolongado e sessões aguardando concessão de memória
        no SQL Server, incluindo informações de conexão, aplicação cliente, login,
        wait_type, bloqueadora, percent_complete e texto da query.

    Main checks:
        - Sessões bloqueadas por mais de 1 hora
        - Sessões aguardando memória por mais de 1 minuto

    Requirements:
        - Permissão VIEW SERVER STATE
        - Acesso à msdb para identificação de SQL Agent Jobs
*/

with con_ses as (
  select c.session_id sid, cast(c.connect_time as datetime2(0)) connect_time
       , rtrim(ltrim(rtrim(coalesce(c.net_transport,'')+' '+(case when len(ltrim(rtrim(s.host_name)))>0 then s.host_name else coalesce(c.client_net_address,'') end)))) origem
       , c.auth_scheme, c.encrypt_option, c.client_net_address, s.host_name
       , (case when len(ltrim(rtrim(coalesce(s.login_name,''))))>0 then s.login_name else '('+s.original_login_name+')' end) login_name
       , s.program_name appl, s.client_interface_name cli_interface
       , s.status ses_status, cast(s.last_request_start_time as datetime2(0)) req_start
       , db_name(s.database_id) DBname, s.open_transaction_count opentrans
       , r.status req_status, r.command, r.blocking_session_id bloqueadora, r.wait_type, r.wait_time, r.wait_resource
       , r.start_time, r.percent_complete
       , SUBSTRING(t.TEXT, r.statement_start_offset/2+1,
         ((CASE WHEN r.statement_end_offset=-1 THEN LEN(CONVERT(NVARCHAR(MAX),t.TEXT))*2 ELSE r.statement_end_offset END)-r.statement_start_offset)/2+1) queryText
  from sys.dm_exec_connections c with(nolock)
  join sys.dm_exec_sessions s with(nolock) on s.session_id=c.session_id
  left outer join sys.dm_exec_requests r with(nolock) on r.session_id=c.session_id
  CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
  where c.session_id<>@@SPID )
, mem as (
  SELECT session_id, max(dop) dop, sum(requested_memory_kb)/1024 MB_Req, sum(granted_memory_kb)/1024 MB_Grant, sum(wait_time_ms)/1000 Wait_s
  FROM sys.dm_exec_query_memory_grants
  group by session_id )
, dados as (
  select sid, con_ses.DBname, con_ses.connect_time, replace(con_ses.origem,'Shared memory ','') origem, con_ses.login_name, client_net_address, host_name
        , COALESCE('[JOB '+j.name+'] ','')
        + (CASE WHEN con_ses.cli_interface like 'Framework %' THEN replace(con_ses.cli_interface,'Framework ','')+' - ' WHEN con_ses.cli_interface=con_ses.appl then '' ELSE con_ses.cli_interface+' - ' END)
        + REPLACE((case when con_ses.appl like '%_{_%}_%' then left(con_ses.appl,charindex('{',con_ses.appl))+'...'+substring(con_ses.appl,charindex('}',con_ses.appl),len(con_ses.appl)) else con_ses.appl end)
          , 'Microsoft SQL Server Management Studio','SSMS') client_application
        , auth_scheme, encrypt_option, ses_status, con_ses.command
        , substring(convert(varchar, con_ses.start_time, 120),6,11) start_time, round(con_ses.percent_complete,2) percent_complete, req_status
        , (case when con_ses.bloqueadora>0 then con_ses.bloqueadora else null end) bloqueadora
        , con_ses.wait_type, con_ses.wait_time/1000 wait_s, con_ses.wait_resource, m.dop, m.MB_Req, m.MB_Grant, m.Wait_s MemWait_s
        , con_ses.queryText
  from con_ses
  left outer join mem m on m.session_id=con_ses.sid
  left outer join msdb.dbo.sysjobs j on (SUBSTRING(MASTER.dbo.FN_VARBINTOHEXSTR(CONVERT(VARBINARY(16), j.JOB_ID)),1,10)) = SUBSTRING(con_ses.appl,30,10)
  where (m.Wait_s > 0 or ses_status is not null)
  and (case when ses_status='suspended' and wait_type='LCK_M_U' and queryText like 'UPDATE TOPIC_CONTROL %' then 1 else 0 end)=0 )
select * from dados
where (bloqueadora is not null and wait_s>3600) -- aguardando lock por mais de 1 hora
or MemWait_s>60 -- aguardando memoria por mais de 1 minuto;
 
