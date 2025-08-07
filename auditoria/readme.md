# SQL Server Audit Framework

Este repositório contém um script **T-SQL completo** para implementação de um processo de auditoria no SQL Server, incluindo:

- Criação de diretório para armazenar arquivos de auditoria.
- Configuração de **Server Audits** e **Audit Specifications**.
- Criação de tabelas para armazenar logs de auditoria.
- Procedures para **coleta** e **purga** de registros.
- Automação do processo via **SQL Agent Job**.

## 📌 Recursos implementados

- Auditoria de logons bem-sucedidos e com falha.
- Auditoria de mudanças em permissões, funções e objetos.
- Auditoria de uso do `xp_cmdshell`.
- Coleta automática dos arquivos `.sqlaudit` para tabelas SQL.
- Purga automática de registros antigos (500 dias).
- Criação automática de diretório (verifica existência antes).
- Execução agendada via SQL Agent a cada 4 horas.

## 🛠 Pré-requisitos

- SQL Server 2016 ou superior.
- Permissão para criar **Audits** e **Audit Specifications**.
- Permissão para criar tabelas e procedures no banco `DB_DBA` (ou ajuste o script para outro banco).
- Permissão para criar jobs no **SQL Server Agent**.
- Permissão para executar `xp_cmdshell` (habilitado previamente).

## 📂 Estrutura do script

1. **Verificação e criação de diretório**
   - Caminho padrão: `G:\MSSQL\SQLAudits`
   - Alterar no script se necessário.

2. **Criação dos Audits**
   - `LogonAttempts-Audit`
   - `Default_SQLAudit`
   - `cmdshell`

3. **Criação das Audit Specifications**
   - `Default-ServerAuditSpecification`
   - `LogonAttempts-AuditSpecification`
   - `Audit-cmdshell`

4. **Criação das tabelas**
   - `tblSQLAuditCollectionStatus`
   - `tblSQLAuditLogs`

5. **Procedures**
   - `usp_SQLAudit_CollectAudits` → Coleta registros de auditoria para o SQL Server.
   - `usp_SQLAudit_PurgeAudits` → Remove registros antigos.

6. **SQL Agent Job**
   - Nome: `SQLAudit_CollectAuditLogs`
   - Passos:
     1. Coleta dos logs.
     2. Purga de registros antigos.
   - Frequência: a cada 4 horas.

## 🚀 Como usar

1. Abra o SQL Server Management Studio (SSMS).
2. Execute o script `sql_audit_framework.sql` no banco `master` e `DB_DBA`.
3. Verifique se:
   - O diretório de auditoria foi criado.
   - Os audits foram habilitados (`SELECT * FROM sys.server_audits`).
   - O job do SQL Agent foi criado.
4. Aguarde a primeira execução automática ou rode manualmente:
   ```sql
   EXEC DB_DBA.dbo.usp_SQLAudit_CollectAudits;
