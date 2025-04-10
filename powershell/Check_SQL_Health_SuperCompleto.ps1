# Check_SQL_Health_SuperCompleto.ps1
# Script de verificação completa do SQL Server com checagens avançadas

$SqlInstance = "localhost"
$RelatorioPath = "C:\Relatorios\Relatorio_SQL_Health.html"
$DataHora = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$Saida = @()
$Conexao = New-Object System.Data.SqlClient.SqlConnection
$Conexao.ConnectionString = "Server=$SqlInstance;Database=master;Integrated Security=True"
$Conexao.Open()

# Garante a existência da pasta do relatório
$relatorioDir = Split-Path -Path $RelatorioPath
if (!(Test-Path -Path $relatorioDir)) {
    New-Item -Path $relatorioDir -ItemType Directory -Force | Out-Null
}

function Add-Log {
    param([string]$Titulo, [string]$Conteudo)
    $Saida += "<h3>$Titulo</h3>" + $Conteudo
}

# Adiciona os blocos já conhecidos e os avançados em sequência
# (Resumo dos blocos omitido aqui por simplicidade de visualização)

# Bloco adicional: Jobs com falha recente
$cmd = $Conexao.CreateCommand()
$cmd.CommandText = @"
SELECT j.name AS JobName, h.run_date, h.run_time, h.message
FROM msdb.dbo.sysjobhistory h
JOIN msdb.dbo.sysjobs j ON h.job_id = j.job_id
WHERE h.run_status = 0 AND h.step_id <> 0 AND h.run_date >= CONVERT(INT, CONVERT(VARCHAR, GETDATE()-3, 112))
ORDER BY h.run_date DESC, h.run_time DESC
"@
$r = $cmd.ExecuteReader()
$jobsFalha = @()
while ($r.Read()) {
    $jobsFalha += "$($r["JobName"]) - Data: $($r["run_date"]) $($r["run_time"]) - Msg: $($r["message"])"
}
$r.Close()
Add-Log "Jobs com Falha Recente" "<pre>" + ($jobsFalha -join "`n") + "</pre>"

# Bloco adicional: Uso de CPU/RAM do SQL Server
$cpuMem = Get-Counter '\Process(sqlservr*)\% Processor Time','\Process(sqlservr*)\Working Set - Private' | Select-Object -ExpandProperty CounterSamples
$cpu = ($cpuMem | Where-Object {$_.Path -like "*% Processor Time*"}).CookedValue
$ram = ($cpuMem | Where-Object {$_.Path -like "*Working Set - Private*"}).CookedValue
Add-Log "Uso de CPU/RAM do SQL Server" "<pre>CPU: {0:N2}%%`nRAM: {1:N2} MB</pre>" -f $cpu, ($ram / 1MB)

# Bloco adicional: Deadlocks recentes (últimos 3 dias)
$cmd.CommandText = @"
SELECT TOP 10 Text, [LogDate]
FROM sys.fn_get_audit_file('deadlock*.xel', NULL, NULL)
WHERE Text LIKE '%deadlock%' AND LogDate >= DATEADD(day, -3, GETDATE())
ORDER BY LogDate DESC
"@
try {
    $r = $cmd.ExecuteReader()
    $deadlocks = @()
    while ($r.Read()) {
        $deadlocks += "$($r["LogDate"]): $($r["Text"])"
    }
    $r.Close()
    Add-Log "Deadlocks Recentes" "<pre>" + ($deadlocks -join "`n") + "</pre>"
} catch {
    Add-Log "Deadlocks Recentes" "<pre>Não foi possível acessar o Extended Events de deadlocks ou não há deadlocks registrados.</pre>"
}

# Bloco adicional: Status do Availability Group
$cmd.CommandText = @"
SELECT ag.name AS AGName, ars.role_desc, drs.synchronization_state_desc, drs.is_suspended, drs.suspend_reason_desc
FROM sys.availability_groups ag
JOIN sys.dm_hadr_availability_replica_states ars ON ag.group_id = ars.group_id
JOIN sys.dm_hadr_database_replica_states drs ON ars.replica_id = drs.replica_id
"@
try {
    $r = $cmd.ExecuteReader()
    $agStatus = @()
    while ($r.Read()) {
        $agStatus += "AG: $($r["AGName"]) - Papel: $($r["role_desc"]) - Sync: $($r["synchronization_state_desc"]) - Suspenso: $($r["is_suspended"]) - Motivo: $($r["suspend_reason_desc"])"
    }
    $r.Close()
    Add-Log "Status do Availability Group" "<pre>" + ($agStatus -join "`n") + "</pre>"
} catch {
    Add-Log "Status do Availability Group" "<pre>Não há Availability Groups configurados ou erro na consulta.</pre>"
}

# Bloco adicional: Fragmentação de índices (>30%)
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

# Bloco adicional: Modo de recuperação dos bancos
$cmd.CommandText = "SELECT name, recovery_model_desc FROM sys.databases"
$r = $cmd.ExecuteReader()
$recuperacao = "<table><tr><th>Database</th><th>Recovery Model</th></tr>"
while ($r.Read()) {
    $recuperacao += "<tr><td>$($r["name"])</td><td>$($r["recovery_model_desc"])</td></tr>"
}
$r.Close()
$recuperacao += "</table>"
Add-Log "Modo de Recuperação dos Bancos" $recuperacao

# Bloco adicional: Uso do tempdb por sessão
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

# Geração do HTML
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