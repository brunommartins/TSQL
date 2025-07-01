DECLARE @Simulacao BIT = 0; -- 1 = Simulação (safe), 0 = Execução real

IF NOT EXISTS (
    SELECT 1
    FROM sys.dm_hadr_availability_replica_states ars
    JOIN sys.availability_replicas ar ON ars.replica_id = ar.replica_id
    WHERE ars.role_desc = 'PRIMARY'
    AND ars.is_local = 1
)
BEGIN
    PRINT 'Esta instância não é primária em nenhum Availability Group. Encerrando script.'
    RETURN
END

PRINT 'Instância primária detectada. Iniciando sincronização de logins...'

IF OBJECT_ID('tempdb..#LoginsBase') IS NOT NULL DROP TABLE #LoginsBase;
IF OBJECT_ID('tempdb..#LoginsFaltantes') IS NOT NULL DROP TABLE #LoginsFaltantes;

CREATE TABLE #LoginsBase (
    name SYSNAME,
    sid VARBINARY(85),
    type_desc NVARCHAR(60),
    default_database_name SYSNAME,
    is_disabled BIT
);

CREATE TABLE #LoginsFaltantes (
    Replica SYSNAME,
    LoginName SYSNAME
);

-- Coleta logins da instância local
INSERT INTO #LoginsBase
SELECT name, sid, type_desc, default_database_name, is_disabled
FROM sys.sql_logins
WHERE name NOT LIKE '##%' AND name <> 'sa';

-- Cursor para réplicas secundárias
DECLARE @replica SYSNAME, @sql NVARCHAR(MAX), @linkedExists BIT;

DECLARE cur_replica CURSOR FOR
SELECT replica_server_name
FROM sys.availability_replicas ar
JOIN sys.dm_hadr_availability_replica_states ars 
    ON ar.replica_id = ars.replica_id
WHERE ars.is_local = 0;

OPEN cur_replica
FETCH NEXT FROM cur_replica INTO @replica

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Verifica e cria Linked Server se necessário
  SELECT @linkedExists = COUNT(*) FROM sys.servers WHERE name = @replica;

	IF @linkedExists = 0
	BEGIN
		PRINT '🔗 Criando Linked Server: ' + @replica;

		SET @sql = '
		EXEC master.dbo.sp_addlinkedserver @server = N''' + @replica + ''', @srvproduct=N'''', @provider=N''MSOLEDBSQL'', @datasrc=N''' + @replica + '''; 
		EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname = N''' + @replica + ''', @locallogin = NULL , @useself = N''True'';
		EXEC master.dbo.sp_serveroption @server=N''' + @replica + ''', @optname=N''data access'', @optvalue=N''true'';';
    
		IF @Simulacao = 0 EXEC(@sql);
		ELSE PRINT ' [Simulação] Linked Server ''' + @replica + ''' seria criado com DATA ACCESS.';
	END
	ELSE
	BEGIN
		-- Se já existe, garanta que DATA ACCESS está ativado
		SET @sql = '
		EXEC master.dbo.sp_serveroption @server=N''' + @replica + ''', @optname=N''data access'', @optvalue=N''true'';';
        --EXEC(@sql)
		IF @Simulacao = 0 EXEC(@sql);
		ELSE PRINT ' [Simulação] DATA ACCESS seria ativado em ''' + @replica + '''.';
	END

	 
    -- Importa logins que só existem na réplica
    SET @sql = '
    SELECT r.name, r.sid, r.type_desc, r.default_database_name, r.is_disabled
    FROM OPENQUERY([' + @replica + '], 
        ''
        SELECT name, sid, type_desc, default_database_name, is_disabled
        FROM sys.sql_logins
        WHERE name NOT LIKE ''''##%%%%'''' AND name <> ''''sa''''
        '') r
    WHERE NOT EXISTS (
        SELECT 1 FROM #LoginsBase b WHERE b.sid = r.sid
    )';

	
    INSERT INTO #LoginsBase
    EXEC (@sql)

	
    FETCH NEXT FROM cur_replica INTO @replica
END

CLOSE cur_replica
DEALLOCATE cur_replica

-- Verifica faltantes em todas as réplicas (inclusive primário)
DECLARE cur_replica2 CURSOR FOR
SELECT replica_server_name
FROM sys.availability_replicas ar
JOIN sys.dm_hadr_availability_replica_states ars 
    ON ar.replica_id = ars.replica_id;

OPEN cur_replica2
FETCH NEXT FROM cur_replica2 INTO @replica

WHILE @@FETCH_STATUS = 0
BEGIN
		   IF @replica = @@SERVERNAME
		BEGIN
			-- Consulta local (sem Linked Server)
			SET @sql = '
			SELECT ''' + @replica + ''', b.name
			FROM #LoginsBase b
			WHERE NOT EXISTS (
				SELECT 1
				FROM sys.sql_logins r
				WHERE r.name NOT LIKE ''##%'' AND r.name <> ''sa''
				AND r.sid = b.sid
			)';
		END
		ELSE
		BEGIN
			-- Consulta via Linked Server
			SET @sql = '
			SELECT ''' + @replica + ''', b.name
			FROM #LoginsBase b
			WHERE NOT EXISTS (
				SELECT 1
				FROM OPENQUERY([' + @replica + '], 
					''
					SELECT name, sid FROM sys.sql_logins
					WHERE name NOT LIKE ''''##%%%%'''' AND name <> ''''sa''''
					'') r
				WHERE r.sid = b.sid
			)';
		END

    INSERT INTO #LoginsFaltantes (Replica, LoginName)
    EXEC (@sql)

    FETCH NEXT FROM cur_replica2 INTO @replica
END

CLOSE cur_replica2
DEALLOCATE cur_replica2

-- Criação ou simulação
DECLARE @login SYSNAME, @sid VARBINARY(85), @type NVARCHAR(60), @defaultdb SYSNAME, @disabled BIT, @createLoginSQL NVARCHAR(MAX);

DECLARE cur_create CURSOR FOR
SELECT Replica, LoginName FROM #LoginsFaltantes;

OPEN cur_create
FETCH NEXT FROM cur_create INTO @replica, @login

WHILE @@FETCH_STATUS = 0
BEGIN
    SELECT @sid = sid, @type = type_desc, @defaultdb = default_database_name, @disabled = is_disabled
    FROM #LoginsBase WHERE name = @login;

    SET @createLoginSQL = '
    EXEC (N''CREATE LOGIN [' + @login + '] 
        WITH PASSWORD = N''''' + CONVERT(NVARCHAR(100), NEWID()) + ''''', 
        SID = 0x' + CONVERT(NVARCHAR(MAX), CONVERT(VARBINARY(85), @sid), 2) + ',
        DEFAULT_DATABASE = [' + @defaultdb + ']' + 
        CASE WHEN @disabled = 1 THEN ';
        ALTER LOGIN [' + @login + '] DISABLE;' ELSE ';' END + '''
    ) AT [' + @replica + ']';

    IF @Simulacao = 1
        PRINT ' [Simulação] Login [' + @login + '] seria criado em [' + @replica + ']';
    ELSE
    BEGIN
        PRINT ' Criando login [' + @login + '] em [' + @replica + ']';
		print @createLoginSQL
        EXEC (@createLoginSQL);
    END

    FETCH NEXT FROM cur_create INTO @replica, @login
END

CLOSE cur_create
DEALLOCATE cur_create

IF @Simulacao = 1
    PRINT 'Simulação concluída. Nenhum login foi criado.'
ELSE
    PRINT ' Sincronização real concluída com sucesso.';
