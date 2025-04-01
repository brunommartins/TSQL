# 🛠️ TSQL Scripts para SQL Server - Troubleshooting

Este repositório contém uma coleção de scripts T-SQL desenvolvidos para auxiliar na identificação e solução de problemas comuns em ambientes SQL Server.

## 🎯 Objetivos

- Monitorar desempenho de consultas
- Verificar bloqueios, deadlocks e sessões inativas
- Consultar estatísticas de índices e tabelas
- Automatizar tarefas administrativas

## 📁 Estrutura

- `Diagnostico/`: Scripts voltados para investigação de performance e problemas
- `Monitoramento/`: Scripts de acompanhamento em tempo real ou periódicos
- `Utilitarios/`: Scripts auxiliares úteis no dia a dia do DBA

## ▶️ Como utilizar

1. Faça o clone do repositório:
   ```bash
   git clone https://github.com/brunommartins/TSQL.git

Escolha o script de acordo com o tipo de problema que você está enfrentando.

Execute no SQL Server Management Studio com permissões suficientes (preferencialmente sysadmin).

Analise os resultados e aja conforme a necessidade.

📋 Requisitos
SQL Server 2016 ou superior

Permissões de leitura nas DMV’s e objetos de sistema

📌 Exemplos

-- Top 10 queries com maior tempo de CPU médio
SELECT TOP 10
    total_worker_time / execution_count AS AvgCPUTime,
    execution_count,
    query_hash
FROM sys.dm_exec_query_stats
ORDER BY AvgCPUTime DESC


🤝 Contribuições

Contribuições são bem-vindas! Veja mais em CONTRIBUTING.md.

