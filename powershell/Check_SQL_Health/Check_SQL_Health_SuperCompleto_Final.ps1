# Check_SQL_Health_SuperCompleto_Final.ps1
# Script completo para verificação de saúde do SQL Server com todas as validações

$SqlInstance = "localhost"
$RelatorioPath = "C:\Relatorios\Relatorio_SQL_Health.html"
$DataHora = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$Saida = @()

# Criar pasta se não existir
$relatorioDir = Split-Path -Path $RelatorioPath
if (!(Test-Path -Path $relatorioDir)) {
    New-Item -Path $relatorioDir -ItemType Directory -Force | Out-Null
}

# Abrir conexão
$Conexao = New-Object System.Data.SqlClient.SqlConnection
$Conexao.ConnectionString = "Server=$SqlInstance;Database=master;Integrated Security=True"
$Conexao.Open()

function Add-Log {
    param([string]$Titulo, [string]$Conteudo)
    $Saida += "<h3>$Titulo</h3>" + $Conteudo
}

# STATUS DOS SERVIÇOS
$SqlServices = Get-Service | Where-Object {
    $_.DisplayName -like "*SQL Server (*" -or $_.DisplayName -like "*SQL Server Agent*"
}
foreach ($svc in $SqlServices) {
    $status = switch ($svc.Status) {
        "Running" { "✅ Rodando" }
        "Stopped" { "❌ Parado" }
        default { "⚠️ $($_.Status)" }
    }
    Add-Log "Status do Serviço: $($svc.DisplayName)" "<pre>Status: $status</pre>"
}

# CHECKDB
$cmd = $Conexao.CreateCommand()
$cmd.CommandText = "SELECT name FROM sys.databases WHERE state_desc = 'ONLINE' AND name NOT IN ('tempdb')"
$reader = $cmd.ExecuteReader()
$Databases = @()
while ($reader.Read()) { $Databases += $reader["name"] }
$reader.Close()
foreach ($db in $Databases) {
    $cmd.CommandText = "DBCC CHECKDB([$db]) WITH NO_INFOMSGS, ALL_ERRORMSGS;"
    try {
        $r = $cmd.ExecuteReader()
        $output = ""
        while ($r.Read()) { $output += $r[0] + "`n" }
        $r.Close()
        $output = if ($output) { "<pre>$output</pre>" } else { "<pre>Sem erros encontrados</pre>" }
        Add-Log "CHECKDB: $db" $output
    } catch {
        Add-Log "CHECKDB: $db (ERRO)" "<pre>$($_.Exception.Message)</pre>"
    }
}

# BACKUPS
$cmd.CommandText = @"
SELECT d.name AS DatabaseName,
MAX(CASE WHEN b.type = 'D' THEN b.backup_finish_date END) AS LastFull,
MAX(CASE WHEN b.type = 'I' THEN b.backup_finish_date END) AS LastDiff,
MAX(CASE WHEN b.type = 'L' THEN b.backup_finish_date END) AS LastLog
FROM sys.databases d
LEFT JOIN msdb.dbo.backupset b ON d.name = b.database_name
GROUP BY d.name
"@
$r = $cmd.ExecuteReader()
$table = "<table><tr><th>Database</th><th>Full</th><th>Diff</th><th>Log</th></tr>"
while ($r.Read()) {
    $table += "<tr><td>$($r[0])</td><td>$($r[1])</td><td>$($r[2])</td><td>$($r[3])</td></tr>"
}
$r.Close()
$table += "</table>"
Add-Log "Últimos Backups" $table

# SESSÕES AGRUPADAS
$cmd.CommandText = @"
SELECT host_name, login_name, COUNT(session_id) AS SessaoTotal
FROM sys.dm_exec_sessions
WHERE is_user_process = 1
GROUP BY host_name, login_name
ORDER BY SessaoTotal DESC
"@
$r = $cmd.ExecuteReader()
$sessaoTabela = "<table><tr><th>Host</th><th>Login</th><th>Total de Sessões</th></tr>"
while ($r.Read()) {
    $sessaoTabela += "<tr><td>$($r["host_name"])</td><td>$($r["login_name"])</td><td>$($r["SessaoTotal"])</td></tr>"
}
$r.Close()
$sessaoTabela += "</table>"
Add-Log "Sessões Ativas por Host/Login" $sessaoTabela

# LOGINS BLOQUEADOS
$cmd.CommandText = "SELECT name, create_date, modify_date FROM sys.sql_logins WHERE is_disabled = 1 OR is_locked = 1"
$r = $cmd.ExecuteReader()
$bloqueados = @()
while ($r.Read()) {
    $bloqueados += "Login: $($r["name"]) - Criado: $($r["create_date"]) - Última modificação: $($r["modify_date"])"
}
$r.Close()
Add-Log "Usuários Bloqueados/Desativados" "<pre>" + ($bloqueados -join "`n") + "</pre>"

# ESPAÇO EM DISCO
$discos = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Free -gt 0 }
$espaco = $discos | ForEach-Object {
    "{0}: {1:N2} GB livres de {2:N2} GB" -f $_.Name, ($_.Free/1GB), ($_.Used + $_.Free)/1GB
}
Add-Log "Espaço em Disco" "<pre>" + ($espaco -join "`n") + "</pre>"

# MTU
$mtus = netsh interface ipv4 show subinterfaces
Add-Log "MTU das Interfaces de Rede" "<pre>$mtus</pre>"

# ERROLOG SQL
$cmd.CommandText = @"
EXEC xp_readerrorlog 0, 1, N'error'
UNION
EXEC xp_readerrorlog 0, 1, N'fail'
UNION
EXEC xp_readerrorlog 0, 1, N'I/O'
UNION
EXEC xp_readerrorlog 0, 1, N'severity'
UNION
EXEC xp_readerrorlog 0, 1, N'deadlock'
ORDER BY LogDate DESC
"@
try {
    $r = $cmd.ExecuteReader()
    $logs = @()
    while ($r.Read()) {
        $logs += "$($r["LogDate"]): $($r["Text"])"
    }
    $r.Close()
    Add-Log "Erros Recentes no SQL Server Error Log" "<pre>" + ($logs | Select-Object -First 100 -join "`n") + "</pre>"
} catch {
    Add-Log "Erro na leitura do Error Log" "<pre>$($_.Exception.Message)</pre>"
}



# JOBS COM FALHA RECENTE
$cmd.CommandText = @"
SELECT TOP 10 j.name AS JobName, h.run_date, h.run_time, h.message
FROM msdb.dbo.sysjobhistory h
JOIN msdb.dbo.sysjobs j ON h.job_id = j.job_id
WHERE h.run_status = 0 AND h.step_id <> 0
ORDER BY h.run_date DESC, h.run_time DESC
"@
$r = $cmd.ExecuteReader()
$jobsFalha = @()
while ($r.Read()) {
    $jobsFalha += "$($r["JobName"]) - Data: $($r["run_date"]) $($r["run_time"]) - Msg: $($r["message"])"
}
$r.Close()
Add-Log "Jobs com Falha Recente" "<pre>" + ($jobsFalha -join "`n") + "</pre>"

# USO DE CPU E RAM DO SQL SERVER
try {
    $cpuMem = Get-Counter '\Process(sqlservr*)\% Processor Time','\Process(sqlservr*)\Working Set - Private' | Select-Object -ExpandProperty CounterSamples
    $cpu = ($cpuMem | Where-Object {$_.Path -like "*% Processor Time*"}).CookedValue
    $ram = ($cpuMem | Where-Object {$_.Path -like "*Working Set*"}).CookedValue
    Add-Log "Uso de CPU/RAM do SQL Server" "<pre>CPU: {0:N2}%%`nRAM: {1:N2} MB</pre>" -f $cpu, ($ram / 1MB)
} catch {
    Add-Log "Uso de CPU/RAM do SQL Server" "<pre>Erro ao coletar métricas: $($_.Exception.Message)</pre>"
}

# DEADLOCKS RECENTES (via XEL)
try {
    $cmd.CommandText = "SELECT TOP 10 Text, [LogDate] FROM sys.fn_get_audit_file('deadlock*.xel', NULL, NULL) WHERE Text LIKE '%deadlock%' ORDER BY LogDate DESC"
    $r = $cmd.ExecuteReader()
    $deadlocks = @()
    while ($r.Read()) {
        $deadlocks += "$($r["LogDate"]): $($r["Text"])"
    }
    $r.Close()
    Add-Log "Deadlocks Recentes" "<pre>" + ($deadlocks -join "`n") + "</pre>"
} catch {
    Add-Log "Deadlocks Recentes" "<pre>Erro ou nenhum evento encontrado.</pre>"
}

# STATUS DO AVAILABILITY GROUP
try {
    $cmd.CommandText = @"
    SELECT ag.name AS AGName, ars.role_desc, drs.synchronization_state_desc, drs.is_suspended, drs.suspend_reason_desc
    FROM sys.availability_groups ag
    JOIN sys.dm_hadr_availability_replica_states ars ON ag.group_id = ars.group_id
    JOIN sys.dm_hadr_database_replica_states drs ON ars.replica_id = drs.replica_id
    "@
    $r = $cmd.ExecuteReader()
    $agStatus = @()
    while ($r.Read()) {
        $agStatus += "AG: $($r["AGName"]) - Papel: $($r["role_desc"]) - Sync: $($r["synchronization_state_desc"]) - Suspenso: $($r["is_suspended"]) - Motivo: $($r["suspend_reason_desc"])"
    }
    $r.Close()
    Add-Log "Status do Availability Group" "<pre>" + ($agStatus -join "`n") + "</pre>"
} catch {
    Add-Log "Status do Availability Group" "<pre>Erro ao consultar AG ou não configurado.</pre>"
}

# FRAGMENTAÇÃO DE ÍNDICES > 30%
$cmd.CommandText = @"
SELECT db_name() AS DBName, OBJECT_NAME(i.object_id) AS TableName, i.name AS IndexName,
       ps.avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ps
JOIN sys.indexes i ON ps.object_id = i.object_id AND ps.index_id = i.index_id
WHERE ps.avg_fragmentation_in_percent > 30
ORDER BY ps.avg_fragmentation_in_percent DESC
"@
try {
    $r = $cmd.ExecuteReader()
    $fragmentados = @()
    while ($r.Read()) {
        $fragmentados += "Tabela: $($r["TableName"]), Índice: $($r["IndexName"]), Fragmentação: $($r["avg_fragmentation_in_percent"])%"
    }
    $r.Close()
    Add-Log "Índices com Alta Fragmentação (>30%)" "<pre>" + ($fragmentados -join "`n") + "</pre>"
} catch {
    Add-Log "Fragmentação de Índices" "<pre>Erro ao coletar dados de fragmentação.</pre>"
}

# MODO DE RECUPERAÇÃO
$cmd.CommandText = "SELECT name, recovery_model_desc FROM sys.databases"
$r = $cmd.ExecuteReader()
$recuperacao = "<table><tr><th>Database</th><th>Recovery Model</th></tr>"
while ($r.Read()) {
    $recuperacao += "<tr><td>$($r["name"])</td><td>$($r["recovery_model_desc"])</td></tr>"
}
$r.Close()
$recuperacao += "</table>"
Add-Log "Modo de Recuperação dos Bancos" $recuperacao

# USO DO TEMPDB POR SESSÃO
$cmd.CommandText = @"
SELECT session_id, SUM(internal_objects_alloc_page_count + user_objects_alloc_page_count)*8/1024 AS tempdb_MB
FROM sys.dm_db_session_space_usage
GROUP BY session_id
ORDER BY tempdb_MB DESC
"@
$r = $cmd.ExecuteReader()
$tempdb = "<table><tr><th>Session ID</th><th>Uso TempDB (MB)</th></tr>"
while ($r.Read()) {
    $tempdb += "<tr><td>$($r["session_id"])</td><td>$($r["tempdb_MB"])</td></tr>"
}
$r.Close()
$tempdb += "</table>"
Add-Log "Uso do TempDB por Sessão" $tempdb


# HTML FINAL
$html = @"
<html>
<head>
    <title>Relatório de Saúde SQL Server</title>
    <style>
        body {{ font-family: Arial; font-size: 13px; margin: 20px; }}
        h2 {{ color: navy; }}
        h3 {{ color: #444; }}
        pre {{ background-color: #f4f4f4; padding: 10px; border: 1px solid #ddd; overflow-x: auto; }}
        table {{ border-collapse: collapse; width: 100%; margin-bottom: 20px; }}
        table, th, td {{ border: 1px solid #ccc; }}
        th, td {{ padding: 8px; text-align: left; }}
        th {{ background-color: #f0f0f0; }}
    </style>
</head>
<body>
<h2>Relatório de Saúde - $SqlInstance</h2>
<p>Gerado em: $DataHora</p>
$($Saida -join "`n")
</body></html>
"@
$html | Out-File -FilePath $RelatorioPath -Encoding UTF8
$Conexao.Close()
Write-Host "Relatório gerado em $RelatorioPath"
