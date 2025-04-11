# Check_SQL_Health_SuperCompleto_Final.ps1

Este script PowerShell realiza uma **verificação de saúde completa e avançada** de uma instância do SQL Server, gerando um relatório em HTML com todas as informações críticas de infraestrutura, banco de dados e desempenho.

---

## ✅ Funcionalidades implementadas

### 🔧 Infraestrutura
- Verifica se os serviços **SQL Server** e **SQL Server Agent** estão ativos.
- Cria automaticamente o diretório do relatório (`C:\Relatorios`) se não existir.

### 📦 Bancos de Dados
- Executa `DBCC CHECKDB` em todas as bases online (exceto `tempdb`).
- Verifica o **modo de recuperação** (`FULL`, `SIMPLE`, `BULK_LOGGED`) para cada banco.
- Coleta os **últimos backups**: Full, Differential e Log.

### 🔐 Acessos e Sessões
- Identifica **logins bloqueados ou desativados**.
- Lista sessões ativas agrupadas por **host e login**.
- Monitora o **uso do `tempdb` por sessão**.

### 💽 Disco e Sistema
- Verifica **espaço em disco** (C:, D:, etc.).
- Mostra **MTU das interfaces de rede** com `netsh`.
- Analisa **arquivos MDF, LDF e NDF** quanto a:
  - Porcentagem livre
  - Tipo de crescimento (por MB ou %)

### ⚙️ Performance e Diagnóstico
- Verifica o **uso atual de CPU e RAM** do SQL Server.
- Detecta **deadlocks** recentes via Extended Events (`.xel`).
- Lista **índices fragmentados** com mais de 30%.
- Coleta erros críticos do **SQL Server Error Log**.

### 📅 Agendamentos e Jobs
- Lista **jobs com falha recente** (últimos 3 dias) e mensagens de erro.

### 🔁 Alta Disponibilidade
- Verifica o **status dos Availability Groups (AG)**:
  - Papel da réplica
  - Sincronização
  - Suspensões e motivos

---

## 📄 Saída

- Gera um arquivo HTML formatado com tabelas, seções, e dados formatados:
  ```
  C:\Relatorios\Relatorio_SQL_Health.html
  ```

---

## 🛠️ Requisitos

- PowerShell 5.1 ou superior
- Conta com permissões de leitura em:
  - SQL Server (`master`, `msdb`)
  - Event Logs do Windows
  - Contadores de performance
- Permissões para usar `xp_readerrorlog`, DMV, XEL (para deadlocks)

---

## 📅 Sugestão de agendamento

Agende o script via **Task Scheduler**:

```bash
powershell.exe -ExecutionPolicy Bypass -File "C:\Scripts\Check_SQL_Health_SuperCompleto_Final.ps1"
```

Frequência recomendada: **Diária** ou **Semanal**, dependendo do ambiente.

---

## 📦 Extensões futuras (sugestões)

- [ ] Envio automático do relatório por e-mail (HTML/anexo)
- [ ] Gravar resultados em banco SQL para histórico
- [ ] Geração de alertas por SNMP, webhook, Teams, etc.
- [ ] Integração com dashboards (Power BI, Grafana)

---

**Autor:** Bruno de Melo Martins  
Especialista em SQL Server, Alta Disponibilidade, Performance e Automação com PowerShell.