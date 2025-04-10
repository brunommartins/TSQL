# Scripts PowerShell

Esta pasta contém scripts desenvolvidos para administração de ambientes SQL Server e infraestrutura em geral.

**Importante:** devido a restrições do ambiente onde os scripts são mantidos, todos os arquivos estão com a extensão `.txt`.

### Como utilizar os scripts

1. Faça o download do arquivo `.txt` desejado.
2. Renomeie a extensão de `.txt` para `.ps1`.
3. Execute o script no PowerShell conforme apropriado.

### Scripts disponíveis

- `ag_dict_failover_management.txt` – Gerencia dinamicamente réplicas síncronas em AG do ambiente DICT.
- `check_ag_health.txt` – Verifica a integridade das réplicas em um AG.
- `check_log_space.txt` – Monitora o espaço disponível nos logs de transação.
- `check_server_network_config.txt` – Coleta e exibe a configuração de rede dos servidores.
- `diagnostico_geral_sqlserver.txt` – Realiza um diagnóstico completo de instâncias SQL Server.
- `rename_interfaces_from_sql.txt` – Renomeia interfaces de rede com base em informações armazenadas no banco de dados.
- `space_disks_check.txt` – Verifica espaço livre nos discos do servidor.
- `test_smtp.txt` – Realiza teste de envio de e-mails via SMTP.
- `verifica_erros_logs_eventviewer_sql.txt` – Analisa o Event Viewer e logs SQL em busca de erros críticos.

> Para facilitar o uso em ambientes com bloqueios a arquivos `.ps1`, todos os scripts estão salvos como `.txt`.

---

Para dúvidas, sugestões ou melhorias, fique à vontade para abrir uma issue ou enviar um pull request.