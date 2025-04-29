SELECT c.credential_id, c.credential_identity,c.name AS Credential_Name,  p.name AS Proxy_Name, p.enabled, p.description
FROM master.sys.credentials c
LEFT JOIN msdb..sysproxies p
ON  c.credential_id = p.credential_id
go
