--VA1018 / CIS, FedRAMP / Latest updates should be installed

--VA1023 / CIS, FedRAMP / CLR should be disabled
	IF EXISTS (SELECT 1 FROM sys.configurations WHERE [name] = 'clr enabled' AND [value] = 1)
		SELECT @@SERVERNAME AS sql_instance, 'VA1023' AS vulnerability, 'clr hosting should be disabled' AS [description]
	ELSE
		SELECT @@SERVERNAME AS sql_instance, 'VA1023' AS vulnerability, '' AS [description]
 
--VA1026 / CIS, FedRAMP / CLR should be disabled
	IF ((SELECT COUNT(*) FROM sys.configurations WHERE [name] IN ('clr enabled','clr strict security') AND [value] = 1) = 2)
		SELECT @@SERVERNAME AS sql_instance, 'VA1026' AS vulnerability, 'clr hosting should be disabled even though clr strict security is enabled' AS [description]
	ELSE
		SELECT @@SERVERNAME AS sql_instance, 'VA1026' AS vulnerability, '' AS [description]
 
--VA1027 / Minimal set of principals should be members of fixed high impact database roles
	IF EXISTS (SELECT 1 FROM sys.configurations WHERE [name] = 'clr enabled' AND CAST([value] AS INT) = 1)
		AND EXISTS (SELECT 1 FROM sys.trusted_assemblies)
		SELECT @@SERVERNAME AS sql_instance, 'VA1027' AS vulnerability, CONCAT('assembly ',QUOTENAME([hash]),' should be either removed or marked as baseline') AS [description]
		--,[hash] AS [assembly], created_by AS [created_by], create_date as [creation_date]
		FROM sys.trusted_assemblies;
	ELSE
		SELECT @@SERVERNAME AS sql_instance, 'VA1027' AS vulnerability, '' AS [description]
		--,'' AS [db_name],'' AS [principal],'' AS [role],'' AS [principal_type]
 
--VA1046 / CIS, FedRAMP / CHECK_POLICY should be enabled for all SQL logins
	IF EXISTS (SELECT 1 FROM sys.sql_logins WHERE is_policy_checked = 0)
		SELECT @@SERVERNAME AS sql_instance, 'VA1046' AS vulnerability, CONCAT('login ',QUOTENAME([name]),' should have policy checked') AS [description]
		--,[name] AS sql_login, CONCAT('ALTER LOGIN ',QUOTENAME([name],' WITH CHECK_POLICY = ON;')) AS fix_cmd
		FROM sys.sql_logins WHERE is_policy_checked = 0;
	ELSE
		SELECT @@SERVERNAME AS sql_instance, 'VA1046' AS vulnerability, '' AS [description]
		--,'' AS sql_login, '' AS fix_cmd;
 
--VA1047 / CIS, FedRAMP / Password expiration check should be enabled for all SQL logins
	IF EXISTS (SELECT 1 FROM sys.sql_logins WHERE is_expiration_checked = 0 AND is_disabled = 0 AND name != '##MS_PolicyTsqlExecutionLogin##' AND name != '##MS_PolicyEventProcessingLogin##')
		SELECT @@SERVERNAME AS sql_instance, 'VA1047' AS vulnerability, CONCAT('login ',QUOTENAME([name]),' should have password expiration checked') AS [description]
		--,[name] AS sql_login, CONCAT('ALTER LOGIN ',QUOTENAME([name]),' WITH CHECK_EXPIRATION = ON;') AS fix_cmd
		FROM sys.sql_logins WHERE is_expiration_checked = 0 AND is_disabled = 0 AND name != '##MS_PolicyTsqlExecutionLogin##' AND name != '##MS_PolicyEventProcessingLogin##';
	ELSE
		SELECT @@SERVERNAME AS sql_instance, 'VA1047' AS vulnerability, '' AS [description]
		--,'' AS sql_login, '' AS fix_cmd;
 
--VA1051 / CIS, FedRAMP / AUTO_CLOSE should be disabled on all databases
	IF EXISTS (SELECT 1 FROM sys.databases WHERE is_auto_close_on = 1)
		SELECT @@SERVERNAME AS sql_instance, 'VA1051' AS vulnerability, CONCAT('database ',QUOTENAME([name]),' should have auto-close option disabled.') AS [description] FROM sys.databases WHERE is_auto_close_on = 1;
	ELSE
		SELECT @@SERVERNAME AS sql_instance, 'VA1051' AS vulnerability, '' AS [description];
 
--VA1052 / CIS, FedRAMP / Remove BUILTIN\Administrators as a server login
	IF EXISTS (SELECT 1 FROM sys.server_principals WHERE [sid] = 0x01020000000000052000000020020000)
		SELECT @@SERVERNAME AS sql_instance, 'VA1052' AS vulnerability, CONCAT('login ',QUOTENAME([name]),' should be dropped') AS [description]
		--,[name] AS sql_login, CONCAT('DROP LOGIN ',QUOTENAME([name],';')) AS fix_cmd
		FROM sys.server_principals WHERE [sid] = 0x01020000000000052000000020020000;
	ELSE
		SELECT @@SERVERNAME AS sql_instance, 'VA1052' AS vulnerability, '' AS [description]
		--,'' AS sql_login, '' AS fix_cmd;
 
--VA1053 / FedRAMP / Account with default name 'sa' should be renamed and disabled
	IF EXISTS (SELECT 1 FROM sys.sql_logins WHERE principal_id = 1 AND (is_disabled = 0 OR [name] = 'sa'))
		SELECT @@SERVERNAME AS sql_instance, 'VA1053' AS vulnerability,CASE WHEN is_disabled = 0 OR [name] = 'sa' THEN CONCAT('login ',QUOTENAME([name]),' should be renamed and disabled') WHEN is_disabled = 1 OR [name] = 'sa' THEN CONCAT('login ',QUOTENAME([name]),' should be renamed') ELSE CONCAT('login ',QUOTENAME([name]),' should be disabled') END AS [description]
		--,[name] AS sql_login,CASE WHEN is_disabled = 0 OR [name] = 'sa' THEN CONCAT('ALTER LOGIN ',QUOTENAME([name]),' DISABLE; ALTER LOGIN ',QUOTENAME([name]),' WITH NAME = [new_name];') WHEN is_disabled = 1 OR [name] = 'sa' THEN CONCAT('ALTER LOGIN ',QUOTENAME([name]),' WITH NAME = [new_name];') ELSE CONCAT('ALTER LOGIN ',QUOTENAME([name]),' DISABLE;') END AS fix_cmd
		FROM sys.sql_logins WHERE principal_id = 1 AND (is_disabled = 0 OR [name] = 'sa')
	ELSE
		SELECT @@SERVERNAME AS sql_instance, 'VA1053' AS vulnerability, '' AS [description]
		--,'' AS sql_login, '' AS fix_cmd;
 
--VA1054 / FedRAMP / Excessive permissions should not be granted to PUBLIC role on objects or columns
	USE tempdb;
	DECLARE @va1054_sql nvarchar(2000)
	IF OBJECT_ID('tempdb.dbo.#entries_to_exclude_va1054', 'U') IS NOT NULL DROP TABLE #entries_to_exclude_va1054;
	IF OBJECT_ID('tempdb.dbo.#va1054', 'U') IS NOT NULL DROP TABLE #va1054;
 
	CREATE TABLE #entries_to_exclude_va1054 (db_name sysname null, object_type varchar(20),schema_name varchar(3),object_name varchar(128),grantor_principal_name varchar(3),permission_name varchar(20),[type] varchar(3),[state] CHAR(1))
	CREATE TABLE #va1054 (db_name sysname, permission sysname,[schema] sysname,[object] sysname)
 
	INSERT INTO #entries_to_exclude_va1054 (object_name)
	VALUES ('fn_sysdac_get_currentusername'),('fn_sysdac_get_username'),('fn_sysdac_is_currentuser_sa'),('fn_sysdac_is_dac_creator'),('fn_sysdac_is_login_creator'),('fn_syspolicy_is_automation_enabled')
 
	UPDATE #entries_to_exclude_va1054
	SET object_type = 'FN',schema_name = 'dbo',grantor_principal_name = 'dbo',permission_name = 'EXECUTE',[type] = 'EX',[state] = 'G'
	WHERE object_type IS NULL
 
	INSERT INTO #entries_to_exclude_va1054 (object_name)
	VALUES ('sp_sysdac_add_history_entry'),('sp_sysdac_add_instance'),('sp_sysdac_delete_history'),('sp_sysdac_delete_instance'),('sp_sysdac_drop_database'),('sp_sysdac_ensure_dac_creator'),('sp_sysdac_rename_database'),('sp_sysdac_resolve_pending_entry'),('sp_sysdac_rollback_all_pending_objects'),('sp_sysdac_rollback_committed_step'),('sp_sysdac_rollback_pending_object'),('sp_sysdac_setreadonly_database'),('sp_sysdac_update_history_entry'),('sp_sysdac_update_instance'),('sp_sysdac_upgrade_instance')
 
	UPDATE #entries_to_exclude_va1054
	SET object_type = 'P',schema_name = 'dbo',grantor_principal_name = 'dbo',permission_name = 'EXECUTE',[type] = 'EX',[state] = 'G'
	WHERE object_type IS NULL
 
	INSERT INTO #entries_to_exclude_va1054 (object_name)
	VALUES ('backupfile'),('backupmediafamily'),('backupmediaset'),('backupset'),('dm_hadr_automatic_seeding_history'),('logmarkhistory'),('restorefile'),('restorefilegroup'),('restorehistory'),('spt_fallback_db'),('spt_fallback_dev'),('spt_fallback_usg'),('spt_monitor'),('suspect_pages'),('sysdac_history_internal'),('sysdac_instances_internal')
 
	UPDATE #entries_to_exclude_va1054
	SET object_type = 'U',schema_name = 'dbo',grantor_principal_name = 'dbo',permission_name = 'SELECT',[type] = 'SL',[state] = 'G'
	WHERE object_type IS NULL
 
	INSERT INTO #entries_to_exclude_va1054 (object_name)
	VALUES ('autoadmin_backup_configuration_summary'),('spt_values'),('sysdac_instances'),('syspolicy_conditions'),('syspolicy_configuration'),('syspolicy_object_sets'),('syspolicy_policies'),('syspolicy_policy_categories'),('syspolicy_policy_category_subscriptions'),('syspolicy_policy_execution_history'),('syspolicy_policy_execution_history_details'),('syspolicy_system_health_state'),('syspolicy_target_set_levels'),('syspolicy_target_sets')
 
	UPDATE #entries_to_exclude_va1054
	SET object_type = 'V',schema_name = 'dbo',grantor_principal_name = 'dbo',permission_name = 'SELECT',[type] = 'SL',[state] = 'G'
	WHERE object_type IS NULL
 

	SET @va1054_sql = 'USE [?]
	INSERT INTO #va1054
	SELECT DB_NAME() AS [db_name]
		,all_entries.permission_name AS [permission]
		,all_entries.schema_name AS [schema]
		,all_entries.object_name AS [object]
	FROM (
		SELECT objs.[type] COLLATE database_default AS object_type
			,SCHEMA_NAME(schema_id) COLLATE database_default AS schema_name
			,objs.name COLLATE database_default AS object_name
			,USER_NAME(grantor_principal_id) COLLATE database_default AS grantor_principal_name
			,permission_name COLLATE database_default AS permission_name
			,perms.[type] COLLATE database_default AS [type]
			,[state] COLLATE database_default AS [state]
		FROM sys.database_permissions AS perms
		INNER JOIN sys.objects AS objs
		ON objs.object_id = perms.major_id
		WHERE perms.class = 1 AND grantee_principal_id = DATABASE_PRINCIPAL_ID(''public'') AND [state] IN (''G'',''W'')
 
		UNION
 
		SELECT ''system_object'' COLLATE database_default AS object_type
			,''sys'' COLLATE database_default AS schema_name
			,OBJECT_NAME(major_id) COLLATE database_default AS object_name
			,USER_NAME(grantor_principal_id) COLLATE database_default AS grantor_principal_name
			,permission_name COLLATE database_default AS permission_name
			,[type] COLLATE database_default AS [type]
			,[state] COLLATE database_default AS [state]
		FROM sys.database_permissions
		WHERE class = 1 AND grantee_principal_id = DATABASE_PRINCIPAL_ID(''public'') AND OBJECT_NAME(major_id) COLLATE database_default = ''sp_syspolicy_execute_policy'' AND [state] IN (''G'',''W'')
		) AS all_entries
	LEFT JOIN #entries_to_exclude_va1054 ON all_entries.object_type = #entries_to_exclude_va1054.object_type COLLATE database_default
		AND all_entries.schema_name = #entries_to_exclude_va1054.schema_name COLLATE database_default
		AND all_entries.object_name = #entries_to_exclude_va1054.object_name COLLATE database_default
		AND all_entries.grantor_principal_name = #entries_to_exclude_va1054.grantor_principal_name COLLATE database_default
		AND all_entries.permission_name = #entries_to_exclude_va1054.permission_name COLLATE database_default
		AND all_entries.[type] = #entries_to_exclude_va1054.[type] COLLATE database_default
		AND all_entries.[state] = #entries_to_exclude_va1054.[state] COLLATE database_default
	WHERE #entries_to_exclude_va1054.object_name IS NULL'
 
	exec sp_MSforeachdb @va1054_sql
 
	IF NOT EXISTS (SELECT 1 FROM #va1054)
		SELECT @@SERVERNAME AS sql_instance, 'VA1054' AS vulnerability, '' AS [description]
			--,'' AS db_name, '' AS permission, '' AS [schema], '' AS [object]
	ELSE
		SELECT @@SERVERNAME AS sql_instance, 'VA1054' AS vulnerability, CONCAT('Permission ',QUOTENAME(permission),' on ',QUOTENAME([object]),' in database ',QUOTENAME([db_name]),' should be revoked') AS [description]
			--,db_name ,permission, [schema], [object]
		FROM #va1054
 
	DROP TABLE #va1054;
	DROP TABLE #entries_to_exclude_va1054;
 
--VA1058 / CIS, FedRAMP / 'sa' login should be disabled
	IF EXISTS (SELECT 1 FROM sys.sql_logins WHERE principal_id = 1 AND is_disabled = 0)
		SELECT @@SERVERNAME AS sql_instance, 'VA1058' AS vulnerability,CONCAT('login ',QUOTENAME([name]),' should be disabled') AS [description]
		--,[name] AS sql_login, CONCAT('ALTER LOGIN ',QUOTENAME([name]),' DISABLE;') AS fix_cmd
		FROM sys.sql_logins WHERE principal_id = 1 AND is_disabled = 0
	ELSE
		SELECT @@SERVERNAME AS sql_instance, 'VA1058' AS vulnerability, '' AS [description]
		--,'' AS sql_login, '' AS fix_cmd;
 
--VA1059 / CIS, FedRAMP / xp_cmdshell should be disabled
	IF EXISTS (SELECT 1 FROM sys.configurations WHERE [name] = 'xp_cmdshell' AND CAST([value] AS int) = 1)
		SELECT @@SERVERNAME AS sql_instance, 'VA1059' AS vulnerability,'[xp_cmdshell] should be disabled' AS [description]
	ELSE
		SELECT @@SERVERNAME AS sql_instance, 'VA1059' AS vulnerability, '' AS [description]
 
--VA1068 / FedRAMP / Server permissions shouldn't be granted directly to principals
	IF NOT EXISTS (SELECT 1
			FROM sys.server_permissions AS perms
			LEFT JOIN sys.endpoints AS ep ON ep.endpoint_id = perms.major_id
			LEFT JOIN sys.server_principals AS server_principal_object ON server_principal_object.principal_id = perms.major_id
			LEFT JOIN sys.server_principals AS grantee_server_principals ON grantee_server_principals.principal_id = perms.grantee_principal_id
			WHERE grantee_server_principals.type NOT IN ('R','C','G','K') AND perms.type != 'COSQ' AND grantee_server_principals.[name] NOT LIKE '##%##'
				AND grantee_server_principals.sid != 0x010100000000000512000000 -- NT AUTHORITY\SYSTEM
				AND grantee_server_principals.sid != 0x01060000000000055000000066BE57DCFBD0F2D76BF9160C566F792677DCCF00 -- NT SERVICE\HEALTHSERVICE
				AND NOT (( permission_name = 'ALTER ANY EVENT SESSION' AND grantee_server_principals.[name] = 'NT SERVICE\SQLTELEMETRY' + ISNULL('$' + CONVERT(sysname, SERVERPROPERTY('InstanceName')), ''))
					OR ( permission_name = 'CONNECT ANY DATABASE' AND grantee_server_principals.[name] = 'NT SERVICE\SQLTELEMETRY' + ISNULL('$' + CONVERT(sysname, SERVERPROPERTY('InstanceName')), '') )
					OR ( permission_name = 'VIEW ANY DEFINITION' AND grantee_server_principals.[name] = 'NT SERVICE\SQLTELEMETRY' + ISNULL('$' + CONVERT(sysname, SERVERPROPERTY('InstanceName')), '') )
					OR ( permission_name = 'VIEW SERVER STATE' AND grantee_server_principals.[name] = 'NT SERVICE\SQLTELEMETRY' + ISNULL('$' + CONVERT(sysname, SERVERPROPERTY('InstanceName')), '') )))
		SELECT @@SERVERNAME AS sql_instance,'VA1068' AS vulnerability,'' AS [description]
			--,'' AS permission,'' AS permission_class,'' AS [object],'' AS [principal],'' AS [revoke_cmd]
	ELSE
		SELECT
			@@SERVERNAME AS sql_instance,'VA1068' AS vulnerability,CONCAT('principal ',QUOTENAME(grantee_server_principals.[name]),' should have permission ',QUOTENAME(permission_name),' revoked') COLLATE database_default AS [description]
			--,permission_name AS [permission],CASE WHEN perms.class = 101 THEN 'LOGIN' ELSE class_desc END AS [permission_class],CASE WHEN perms.class = 100 THEN @@SERVERNAME WHEN perms.class = 101 THEN server_principal_object.[name] WHEN perms.class = 105 THEN ep.[name] END AS [object],grantee_server_principals.[name] AS [principal],CASE WHEN perms.class = 100 THEN CONCAT('REVOKE ',permission_name,' TO ',QUOTENAME(grantee_server_principals.[name]),' AS ',QUOTENAME(SUSER_SNAME(0x01))) COLLATE database_default WHEN perms.class = 101 THEN server_principal_object.[name] WHEN perms.class = 105 THEN CONCAT('REVOKE ',permission_name,' ON ENDPOINT::',QUOTENAME(ep.[name]),' TO ',QUOTENAME(grantee_server_principals.[name]),' AS ',QUOTENAME(SUSER_SNAME(0x01))) COLLATE database_default END AS [revoke_cmd]
		FROM sys.server_permissions AS perms
		LEFT JOIN sys.endpoints AS ep ON ep.endpoint_id = perms.major_id
		LEFT JOIN sys.server_principals AS server_principal_object ON server_principal_object.principal_id = perms.major_id
		LEFT JOIN sys.server_principals AS grantee_server_principals ON grantee_server_principals.principal_id = perms.grantee_principal_id
		WHERE grantee_server_principals.type NOT IN ('R','C','G','K') AND perms.type != 'COSQ' AND grantee_server_principals.[name] NOT LIKE '##%##'
			AND grantee_server_principals.sid != 0x010100000000000512000000 -- NT AUTHORITY\SYSTEM
			AND grantee_server_principals.sid != 0x01060000000000055000000066BE57DCFBD0F2D76BF9160C566F792677DCCF00 -- NT SERVICE\HEALTHSERVICE
			AND NOT (( permission_name = 'ALTER ANY EVENT SESSION' AND grantee_server_principals.[name] = 'NT SERVICE\SQLTELEMETRY' + ISNULL('$' + CONVERT(sysname, SERVERPROPERTY('InstanceName')), ''))
				OR ( permission_name = 'CONNECT ANY DATABASE' AND grantee_server_principals.[name] = 'NT SERVICE\SQLTELEMETRY' + ISNULL('$' + CONVERT(sysname, SERVERPROPERTY('InstanceName')), '') )
				OR ( permission_name = 'VIEW ANY DEFINITION' AND grantee_server_principals.[name] = 'NT SERVICE\SQLTELEMETRY' + ISNULL('$' + CONVERT(sysname, SERVERPROPERTY('InstanceName')), '') )
				OR ( permission_name = 'VIEW SERVER STATE' AND grantee_server_principals.[name] = 'NT SERVICE\SQLTELEMETRY' + ISNULL('$' + CONVERT(sysname, SERVERPROPERTY('InstanceName')), '') ))
 
--VA1071 / CIS, FedRAMP / 'Scan for startup stored procedures' option should be disabled
	IF EXISTS (SELECT 1 FROM sys.configurations WHERE [name] = 'scan for startup procs' AND CAST([value] AS int) = 1)
		SELECT @@SERVERNAME AS sql_instance, 'VA1059' AS vulnerability,'[scan for startup procs] should be disabled' AS [description]
	ELSE
		SELECT @@SERVERNAME AS sql_instance, 'VA1059' AS vulnerability, '' AS [description]
  
--VA1072 / CIS, FedRAMP / Authentication mode should be Windows Authentication
	IF (CONVERT(int, SERVERPROPERTY('IsIntegratedSecurityOnly')) = 0)
		SELECT @@SERVERNAME AS sql_instance, 'VA1072' AS vulnerability, 'change authentication mode to Windows only' AS [description]
	ELSE
		SELECT @@SERVERNAME AS sql_instance, 'VA1072' AS vulnerability, '' AS [description]
 
--VA1091 / CIS, FedRAMP / Authentication mode should be Windows Authentication
	DECLARE @SmoAuditLevel int;
 
	EXEC master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',N'Software\Microsoft\MSSQLServer\MSSQLServer',N'AuditLevel',@SmoAuditLevel output;
 
	IF (@SmoAuditLevel <> 3)
		SELECT @@SERVERNAME AS sql_instance, 'VA1091' AS vulnerability, 'SQL should be auditing both failed & successful logins' AS [description]
	ELSE
		SELECT @@SERVERNAME AS sql_instance, 'VA1091' AS vulnerability, '' AS [description]
 
--VA1092 / CIS, FedRAMP / SQL Server instance shouldn't be advertised by the SQL Server Browser service
	DECLARE @hidden_val int;
 
	EXEC master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',N'Software\Microsoft\MSSQLServer\MSSQLServer\SuperSocketNetLib',N'HideInstance',@hidden_val output
 
	SELECT
		@@SERVERNAME AS sql_instance,'VA1092' AS vulnerability,CASE WHEN @hidden_val = 0 AND SERVERPROPERTY('IsClustered') = 0 THEN 'instance should be hidden' ELSE '' END AS [description]
 
--VA1093 / CIS, FedRAMP / Maximum number of error logs should be 12 or more
	DECLARE @NumErrorLogs INT;
 
	EXEC master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',N'Software\Microsoft\MSSQLServer\MSSQLServer',N'NumErrorLogs',@NumErrorLogs output;
	IF @NumErrorLogs < 12 OR @NumErrorLogs IS NULL
		SELECT @@SERVERNAME AS sql_instance, 'VA1093' AS vulnerability, 'number of error logs below 12' AS [description];
	ELSE
		SELECT @@SERVERNAME AS sql_instance, 'VA1093' AS vulnerability, '' AS [description];
 
--VA1094 / FedRAMP / Database permissions shouldn't be granted directly to principals
	USE tempdb;
	DECLARE @va1094_sql nvarchar(2000)
	IF OBJECT_ID('tempdb.dbo.#va1094', 'U') IS NOT NULL DROP TABLE #va1094;
 
	CREATE TABLE #va1094 ([db_name] sysname, [permission] sysname, [permission_class] sysname, [class_separator] sysname, [object] sysname, [principal] sysname)
 
	SET @va1094_sql='USE [?]
	INSERT INTO #va1094
	SELECT DB_NAME()
	,permission_name
	,ISNULL(SCHEMA_NAME(b.schema_id),REPLACE(a.class_desc, ''_'', '' ''))
	,CASE WHEN SCHEMA_NAME(b.schema_id) IS NULL THEN ''::'' ELSE ''.'' END
	,CASE WHEN a.class = 0 THEN DB_NAME() WHEN a.class = 1 THEN b.name WHEN a.class = 3 THEN SCHEMA_NAME(major_id) WHEN a.class = 4 THEN k.name WHEN a.class = 5 THEN d.name WHEN a.class = 6 THEN TYPE_NAME(major_id) WHEN a.class = 10 THEN e.name WHEN a.class = 15 THEN f.name COLLATE database_default WHEN a.class = 16 THEN g.name COLLATE database_default WHEN a.class = 17 THEN h.name COLLATE database_default WHEN a.class = 18 THEN i.name COLLATE database_default WHEN a.class = 19 THEN j.name COLLATE database_default WHEN a.class = 23 THEN o.name WHEN a.class = 24 THEN l.name WHEN a.class = 25 THEN n.name WHEN a.class = 26 THEN m.name END
	,c.name
	FROM sys.database_permissions a LEFT JOIN sys.all_objects b ON b.object_id = a.major_id LEFT JOIN sys.database_principals c ON a.grantee_principal_id = c.principal_id LEFT JOIN sys.assemblies d ON a.major_id = d.assembly_id LEFT JOIN sys.xml_schema_collections e ON a.major_id = e.xml_collection_id LEFT JOIN sys.service_message_types f ON a.major_id = f.message_type_id LEFT JOIN sys.service_contracts g ON a.major_id = g.service_contract_id LEFT JOIN sys.services h ON a.major_id = h.service_id LEFT JOIN sys.remote_service_bindings i ON a.major_id = i.remote_service_binding_id LEFT JOIN sys.routes j ON a.major_id = j.route_id LEFT JOIN sys.database_principals k ON a.major_id = k.principal_id LEFT JOIN sys.symmetric_keys l ON a.major_id = l.symmetric_key_id LEFT JOIN sys.asymmetric_keys m ON a.major_id = m.asymmetric_key_id LEFT JOIN sys.certificates n ON a.major_id = n.certificate_id LEFT JOIN sys.fulltext_catalogs o ON a.major_id = o.fulltext_catalog_id
	WHERE (c.type = ''S'' OR c.type = ''W'') AND a.type != ''CO'' AND c.name NOT IN ( ''##MS_PolicyEventProcessingLogin##'',''##MS_PolicyTsqlExecutionLogin##'' ) AND [state] IN (''G'',''W'')'
 
	exec sp_MSforeachdb @va1094_sql
 
	IF NOT EXISTS (SELECT 1 FROM #va1094)
		SELECT @@SERVERNAME AS sql_instance, 'VA1094' AS vulnerability, '' AS [description]
		--,'' AS [db_name],'' AS [permission],'' AS [permission_class],'' AS [class_separator],'' AS [object],'' AS [principal], '' AS revoke_cmd
	ELSE
		SELECT @@SERVERNAME AS sql_instance, 'VA1094' AS vulnerability, CONCAT('principal ',QUOTENAME(principal),' should have permission ',QUOTENAME(permission),' revoked')AS [description]
		--,[db_name],[permission], [permission_class], [class_separator], [object], [principal],CONCAT('REVOKE ',[permission],' ON ',[permission_class],[class_separator],CASE WHEN [permission_class] = 'DATABASE' THEN QUOTENAME([object]) ELSE [object] END,' TO ',QUOTENAME([principal])) AS revoke_cmd
		FROM #va1094
 
	DROP TABLE #va1094;
 
--VA1095 / FedRAMP / Excessive permissions should not be granted to PUBLIC role
	USE tempdb;
	DECLARE @va1095_sql nvarchar(2000)
	IF OBJECT_ID('tempdb.dbo.#va1095', 'U') IS NOT NULL DROP TABLE #va1095;
	CREATE TABLE #va1095 (db_name sysname, permission_class sysname,[object] sysname,permission sysname)
 
	SET @va1095_sql = 'USE [?]
	INSERT INTO #va1095
	SELECT DB_NAME()
	,REPLACE(a.class_desc, ''_'', '' '') [permission_class]
	,CASE WHEN a.class = 0 THEN DB_NAME() WHEN a.class = 3 THEN SCHEMA_NAME(major_id) WHEN a.class = 4 THEN j.name WHEN a.class = 5 THEN c.name WHEN a.class = 6 THEN TYPE_NAME(major_id) WHEN a.class = 10 THEN d.name WHEN a.class = 15 THEN e.name COLLATE database_default WHEN a.class = 16 THEN f.name COLLATE database_default WHEN a.class = 17 THEN g.name COLLATE database_default WHEN a.class = 18 THEN h.name COLLATE database_default WHEN a.class = 19 THEN i.name COLLATE database_default WHEN a.class = 23 THEN n.name WHEN a.class = 24 THEN k.name WHEN a.class = 25 THEN m.name WHEN a.class = 26 THEN l.name END [object]
	,a.permission_name [permission]
	FROM sys.database_permissions a
	LEFT JOIN sys.database_principals b ON a.grantee_principal_id = b.principal_id LEFT JOIN sys.assemblies c ON a.major_id = c.assembly_id LEFT JOIN sys.xml_schema_collections d ON a.major_id = d.xml_collection_id LEFT JOIN sys.service_message_types e ON a.major_id = e.message_type_id LEFT JOIN sys.service_contracts f ON a.major_id = f.service_contract_id LEFT JOIN sys.services g ON a.major_id = g.service_id LEFT JOIN sys.remote_service_bindings h ON a.major_id = h.remote_service_binding_id LEFT JOIN sys.routes i ON a.major_id = i.route_id LEFT JOIN sys.database_principals j ON a.major_id = j.principal_id LEFT JOIN sys.symmetric_keys k ON a.major_id = k.symmetric_key_id LEFT JOIN sys.asymmetric_keys l ON a.major_id = l.asymmetric_key_id LEFT JOIN sys.certificates m ON a.major_id = m.certificate_id LEFT JOIN sys.fulltext_catalogs n ON a.major_id = n.fulltext_catalog_id
	WHERE a.grantee_principal_id = DATABASE_PRINCIPAL_ID(''public'') AND class != 1 AND [state] IN (''G'',''W'') AND NOT (a.class = 0 AND b.name = ''public'' AND a.major_id = 0 AND a.minor_id = 0 AND permission_name IN (''VIEW ANY COLUMN ENCRYPTION KEY DEFINITION'',''VIEW ANY COLUMN MASTER KEY DEFINITION''))'
 
	exec sp_MSforeachdb @va1095_sql
 
	IF NOT EXISTS (SELECT 1 FROM #va1095)
		SELECT @@SERVERNAME AS sql_instance, 'VA1054' AS vulnerability, '' AS [description]
			--,'' AS [db_name], '' AS permission_class, '' AS [object], '' AS permission
	ELSE
		SELECT @@SERVERNAME AS sql_instance, 'VA1054' AS vulnerability, CONCAT('Permission ',QUOTENAME(permission),' on ',QUOTENAME([object]),' in database ',QUOTENAME([db_name]),' should be revoked') AS [description]
			--,[db_name] ,permission_class, [object], [permission]
		FROM #va1095
 
	DROP TABLE #va1095;
 
--VA1102 / CIS, FedRAMP / The Trustworthy bit should be disabled on all databases except MSDB
	IF EXISTS (SELECT 1 FROM sys.databases WHERE LOWER([name]) <> 'msdb' AND is_trustworthy_on = 1)
		SELECT @@SERVERNAME AS sql_instance, 'VA1102' AS vulnerability,CONCAT('database ',[name],' should not have [trustworthy] option enabled') AS [description]
		FROM sys.databases WHERE LOWER([name]) <> 'msdb' AND is_trustworthy_on = 1
	ELSE
		SELECT @@SERVERNAME AS sql_instance, 'VA1102' AS vulnerability, '' AS [description]
 
--VA1143 / FedRAMP / 'dbo' user should not be used for normal service operation
	USE tempdb;
	CREATE TABLE #VA1143_results ([db_name] sysname,violation bit)
 
	exec sp_MSforeachdb
	'USE [?]
	INSERT INTO #VA1143_results
	SELECT DB_NAME() AS [db_name], CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END AS [violation] FROM sys.database_principals WHERE principal_id >= 5 AND principal_id < 16384;'
 
	IF EXISTS (SELECT 1 FROM #VA1143_results WHERE db_name NOT IN ('tempdb','model'))
	BEGIN 
		SELECT
			@@SERVERNAME AS sql_instance,'VA1143' AS vulnerability,CONCAT('In database ',QUOTENAME([db_name]),' [dbo] user shoudl not be used for normal service operation') AS DESCRIPTION
		FROM #VA1143_results WHERE db_name NOT IN ('tempdb','model')
	END
	ELSE BEGIN
			SELECT @@SERVERNAME AS sql_instance, 'VA1143' AS vulnerability,'' AS [description]
	END
 
	DROP TABLE #VA1143_results;
 
--VA1144 / FedRAMP / Model database should only be accessible by 'dbo'
	USE [model]
	IF EXISTS (SELECT 1 FROM sys.database_principals WHERE principal_id >= 5 AND principal_id < 16384)
		SELECT @@SERVERNAME AS sql_instance, 'VA1144' AS vulnerability,CONCAT('login ',QUOTENAME([name]),' should be removed from [model] db') AS [description]
		--,CONCAT('USE [model]; DROP USER ',QUOTENAME([name]),';') AS fix_cmd
		FROM sys.database_principals WHERE principal_id >= 5 AND principal_id < 16384
	ELSE
		SELECT @@SERVERNAME AS sql_instance, 'VA1144' AS vulnerability, '' AS [description]
		--,'' AS fix_cmd;
 
--VA1219 / FedRAMP / Transparent data encryption should be enabled
	IF EXISTS (SELECT 1 FROM sys.databases WHERE is_encrypted = 0 AND database_id > 4)
		SELECT @@SERVERNAME AS sql_instance, 'VA1219' AS vulnerability, CONCAT('database ',QUOTENAME([name]),' should have TDE configured') AS [description]
		--,[name] AS [db_name]
		FROM sys.databases WHERE is_encrypted = 0 AND database_id > 4;
	ELSE
		SELECT @@SERVERNAME AS sql_instance, 'VA1219' AS vulnerability, '' AS [description]
		--,'' AS [db_name]
 
--VA1220 / FedRAMP / Database communication using TDS should be protected through TLS
	IF EXISTS (SELECT DISTINCT net_transport,protocol_type,endpoint_id,auth_scheme FROM sys.dm_exec_connections WHERE session_id IS NOT NULL AND encrypt_option <> 'TRUE' AND net_transport <> 'Shared memory')
		INSERT INTO #va1220
		SELECT @@SERVERNAME AS sql_instance, 'VA1220' AS vulnerability, 'unencrypted sessions are present' AS [description]
	ELSE
		INSERT INTO #va1220
		SELECT @@SERVERNAME AS sql_instance, 'VA1220' AS vulnerability, '' AS [description]
 
--VA1223 / FedRAMP / Certificate keys should use at least 2048 bits
	USE tempdb;
	DECLARE @va1223_sql nvarchar(2000)
	IF OBJECT_ID('tempdb.dbo.#va1223', 'U') IS NOT NULL DROP TABLE #va1223;
 
	CREATE TABLE #va1223 ([db_name] sysname, [certificate_name] sysname, [thumbprint] varbinary(32))
 
	SET @va1223_sql='USE [?]
		INSERT INTO #va1223
		SELECT DB_NAME() AS [db_name], [name] AS [certificate_name], thumbprint AS [thumbprint] FROM sys.certificates WHERE key_length < 2048'
 
	exec sp_MSforeachdb @va1223_sql
 
	IF EXISTS (SELECT 1 FROM #va1223)
		SELECT @@SERVERNAME AS sql_instance, 'VA1223' AS vulnerability, 're-encrypt data with stronger key certificate' AS [description]
		--,[db_name],[certificate_name],[thumbprint]
		FROM #va1223;
	ELSE
		SELECT @@SERVERNAME AS sql_instance, 'VA1223' AS vulnerability, '' AS [description]
		--,'' AS [db_name],'' AS [certificate_name],'' AS [thumbprint]
 
	DROP TABLE #va1223;
 
--VA1230 / FedRAMP / Filestream should be disabled
	DECLARE @enable_lvl int;
 
	EXEC master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer\Filestream', N'EnableLevel', @enable_lvl output;
 
	IF EXISTS (SELECT 1 FROM sys.configurations WHERE [name] = 'filestream access level' AND CAST([value] AS int) <> 0) OR @enable_lvl <> 0
		SELECT @@SERVERNAME AS sql_instance, 'VA1230' AS vulnerability,'Filestream should be disabled' AS [description]
	ELSE
		SELECT @@SERVERNAME AS sql_instance, 'VA1230' AS vulnerability, '' AS [description]
 
--VA1244 / CIS, FedRAMP / Orphaned users should be removed from SQL server databases
	USE tempdb;
	DECLARE @va1244_sql nvarchar(2000)
	IF OBJECT_ID('tempdb.dbo.#va1244', 'U') IS NOT NULL DROP TABLE #va1244;
 
	CREATE TABLE #va1244 ([db_name] sysname, [principal] sysname)
 
	SET @va1244_sql='USE [?]
	INSERT INTO #va1244
	SELECT DB_NAME() AS [db_name], [name] AS [principal]
	FROM sys.database_principals
	WHERE [sid] NOT IN (SELECT [sid] FROM sys.server_principals) AND authentication_type_desc = ''INSTANCE '' AND [type] = ''S '' AND principal_id != 2 AND DATALENGTH([sid]) <= 28'
 
	exec sp_MSforeachdb @va1244_sql
 
	IF EXISTS (SELECT 1 FROM #va1244)
		SELECT @@SERVERNAME AS sql_instance, 'VA1244' AS vulnerability, CONCAT('orphaned user ',QUOTENAME([principal]),' in db ',QUOTENAME([db_name]),' should be removed or re-mapped') AS [description]
		--,[db_name],[principal]
		FROM #va1244;
	ELSE
		SELECT @@SERVERNAME AS sql_instance, 'VA1244' AS vulnerability, '' AS [description]
		--,'' AS [db_name], '' AS [principal]
 
	DROP TABLE #va1244;
 
--VA1245 / FedRAMP / The dbo information should be consistent between the target DB and master
	USE tempdb;
	CREATE TABLE #va1245_results ([db_name] sysname,owner_name sysname,dbo_owner_name sysname NULL)
 
	exec sp_MSforeachdb
	'USE [?]
	INSERT INTO #va1245_results
	SELECT DB_NAME(),SUSER_SNAME(dbs.owner_sid) AS owner_name,SUSER_SNAME(dbprs.sid) AS dbo_owner_name FROM sys.database_principals AS dbprs INNER JOIN sys.databases AS dbs ON dbprs.sid <> dbs.owner_sid WHERE dbs.database_id = DB_ID() AND dbprs.principal_id = 1;'
 
	SELECT
		@@SERVERNAME AS sql_instance,'VA1245' AS vulnerability,CONCAT('Login ',QUOTENAME(owner_name),' is the database owner, but the default [dbo] is owner by ',QUOTENAME(dbo_owner_name)) AS [description]
		--,[db_name] AS affected_db,owner_name AS current_owner,dbo_owner_name AS login_owning_dbo_user,CASE WHEN ISNULL(dbo_owner_name,'') <> SUSER_SNAME(0x01) THEN CONCAT('USE [master]; ALTER AUTHORIZATION ON DATABASE::[',[db_name],'] TO ',QUOTENAME(owner_name),';') ELSE CONCAT('USE [master]; ALTER AUTHORIZATION ON DATABASE::[',[db_name],'] TO ',SUSER_SNAME(0x01),';') END AS remap_owner_cmd ,CASE WHEN dbo_owner_name IS NULL THEN '' WHEN dbo_owner_name <> SUSER_SNAME(0x01) THEN CONCAT('USE [',[db_name],']; CREATE USER ',QUOTENAME(dbo_owner_name),' FOR LOGIN ',QUOTENAME(dbo_owner_name),'; ALTER ROLE [db_owner] ADD MEMBER ',QUOTENAME(dbo_owner_name),';') ELSE CONCAT('USE [',[db_name],']; CREATE USER ',QUOTENAME(owner_name),' FOR LOGIN ',QUOTENAME(owner_name),'; ALTER ROLE [db_owner] ADD MEMBER ',QUOTENAME(owner_name),';') END AS remap_dbo_owner_as_user_cmd
	FROM #va1245_results
 
	IF NOT EXISTS (SELECT 1 FROM #va1245_results)
		BEGIN
			SELECT @@SERVERNAME AS sql_instance, 'VA1245' AS vulnerability,'' AS [description]
			--,'' AS affected_db,'' AS current_owner, '' AS login_owning_dbo_user, '' AS remap_owner_cmd, '' AS remap_dbo_owner_as_user_cmd
		END
 
	DROP TABLE #va1245_results;

--VA1248 / FedRAMP / User-defined database roles should not be members of fixed roles
	USE tempdb;
	DECLARE @va1248_sql nvarchar(2000)
	IF OBJECT_ID('tempdb.dbo.#va1248', 'U') IS NOT NULL DROP TABLE #va1248;
 
	CREATE TABLE #va1248 ([db_name] sysname, [role] sysname, [member] sysname)
 
	SET @va1248_sql='USE [?]
	INSERT INTO #va1248
	SELECT
	DB_NAME() AS db_name
	,USER_NAME(drm.role_principal_id) AS [role]
	,USER_NAME(drm.member_principal_id) AS member
	FROM sys.database_role_members AS drm, sys.database_principals dp
	WHERE drm.member_principal_id = dp.principal_id AND ( drm.role_principal_id >= 16384 AND drm.role_principal_id <= 16393) AND dp.type = ''R'''
 
	exec sp_MSforeachdb @va1248_sql
 
	IF NOT EXISTS (SELECT 1 FROM #va1248)
		SELECT @@SERVERNAME AS sql_instance, 'VA1248' AS vulnerability, '' AS [description]
		--,'' AS [db_name],'' AS [role],'' AS [member],'' AS revoke_cmd
	ELSE
		SELECT @@SERVERNAME AS sql_instance, 'VA1248' AS vulnerability, CONCAT('user-defined role  ',QUOTENAME(member),' should not be a member of role ',QUOTENAME([role]),' revoked in db ',QUOTENAME(db_name))AS [description]
		--,[db_name],[role],[member],CONCAT('USE ',QUOTENAME(db_name),'; ALTER ROLE ',QUOTENAME([role]),' DROP MEMBER ',QUOTENAME([member]),';') AS revoke_cmd
		FROM #va1248
 
	DROP TABLE #va1248;
 
--VA1256 / FedRAMP / User CLR assemblies should not be defined in the database
	USE tempdb;
	DECLARE @va1256_sql nvarchar(2000)
	IF OBJECT_ID('tempdb.dbo.#va1256', 'U') IS NOT NULL DROP TABLE #va1256;
 
	CREATE TABLE #va1256 ([db_name] sysname, [assembly] sysname)
 
	SET @va1256_sql='USE [?]
	INSERT INTO #va1256
	SELECT DB_NAME() AS [db_name], [name] AS [assembly] FROM sys.assemblies WHERE is_user_defined != 0'
 
	exec sp_MSforeachdb @va1256_sql
 
	IF EXISTS (SELECT 1 FROM #va1256)
		SELECT @@SERVERNAME AS sql_instance, 'VA1256' AS vulnerability, CONCAT('assembly ',QUOTENAME([assembly]),' in db ',QUOTENAME([db_name]),' should be removed') AS [description]
		--,[db_name],[assembly]
		FROM #va1256;
	ELSE
		SELECT @@SERVERNAME AS sql_instance, 'VA1256' AS vulnerability, '' AS [description]
		--,'' AS [db_name], '' AS [assembly]
 
	DROP TABLE #va1256;
 
--VA1258 / FedRAMP / Database owners are as expected
	SELECT @@SERVERNAME AS sql_instance, 'VA1258' AS vulnerability, CONCAT('Owner ',QUOTENAME(SUSER_SNAME(owner_sid)),' of database ',QUOTENAME([name]),' should be changed or marked as baseline')
		--,[name] AS [database], SUSER_SNAME(owner_sid) AS [owner]
		FROM sys.databases
 
--VA1264 / CIS / Authentication mode should be Windows Authentication
	DECLARE @success_logon_event int = 0;
	DECLARE @fail_logon_event int = 0;
 
	SELECT @success_logon_event = COUNT(*)
	FROM sys.server_audits adts, sys.server_audit_specifications srvadtspecs, sys.server_audit_specification_details srvadtspecdtls
	WHERE adts.audit_guid = srvadtspecs.audit_guid AND adts.is_state_enabled = 1 AND srvadtspecs.is_state_enabled = 1 AND srvadtspecdtls.audited_result = 'SUCCESS AND FAILURE' AND srvadtspecdtls.audit_action_id = 'LGSD';
 
	SELECT @fail_logon_event = COUNT(*)
	FROM sys.server_audits adts, sys.server_audit_specifications srvadtspecs, sys.server_audit_specification_details srvadtspecdtls
	WHERE adts.audit_guid = srvadtspecs.audit_guid AND adts.is_state_enabled = 1 AND srvadtspecs.is_state_enabled = 1 AND srvadtspecdtls.audited_result = 'SUCCESS AND FAILURE' AND srvadtspecdtls.audit_action_id = 'LGFL';
 
	IF (@success_logon_event = 0 OR @fail_logon_event = 0)
		SELECT @@SERVERNAME AS sql_instance, 'VA1264' AS vulnerability, 'SQL should be auditing both failed & successful logins' AS [description]
	ELSE
		SELECT @@SERVERNAME AS sql_instance, 'VA1264' AS vulnerability, '' AS [description]
 
--VA1279 / FedRAMP / Force encryption should be enabled for TDS
	USE tempdb;
	IF OBJECT_ID('#va1279','U') IS NOT NULL BEGIN DROP TABLE #va1279; END
	CREATE TABLE #va1279 (sql_instance nvarchar(128),vulnerability nvarchar(128), [description] nvarchar(128))
 
	DECLARE @ForceEncryption INT;
 
	EXEC master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer\SuperSocketNetLib', N'ForceEncryption', @ForceEncryption OUTPUT;
 
	IF (@ForceEncryption = 1)
		SELECT @@SERVERNAME AS sql_instance, 'VA1279' AS vulnerability, 'encryption not forced' AS [description]
	ELSE
		SELECT @@SERVERNAME AS sql_instance, 'VA1279' AS vulnerability, '' AS [description]
 
--VA1280 / CIS, FedRAMP  / Server Permissions granted to public should be minimized
	IF NOT EXISTS (SELECT 1
			FROM sys.server_permissions AS perms
			LEFT JOIN sys.endpoints AS ep ON ep.endpoint_id = perms.major_id
			LEFT JOIN sys.server_principals AS prins ON prins.principal_id = perms.major_id
			WHERE grantee_principal_id = SUSER_ID('public')
				AND NOT ((permission_name = 'CONNECT' AND perms.class = 105 AND LOWER(ep.[name]) = 'tsql local machine') OR(permission_name = 'CONNECT' AND perms.class = 105 AND LOWER(ep.[name]) = 'tsql named pipes') OR (permission_name = 'CONNECT' AND perms.class = 105 AND LOWER(ep.[name]) = 'tsql default tcp') OR (permission_name = 'CONNECT' AND perms.class = 105 AND LOWER(ep.[name]) = 'tsql default via') OR (permission_name = 'VIEW ANY DATABASE' AND perms.class = 100)))
		SELECT
			@@SERVERNAME AS sql_instance,'VA1280' AS vulnerability,'' AS [description]
			--,'' AS [permission],'' AS [permission_class],'' AS [object]
		FROM sys.server_permissions AS perms
		LEFT JOIN sys.endpoints AS ep ON ep.endpoint_id = perms.major_id
		LEFT JOIN sys.server_principals AS prins ON prins.principal_id = perms.major_id
		WHERE grantee_principal_id = SUSER_ID('public')
			AND NOT ((permission_name = 'CONNECT' AND perms.class = 105 AND LOWER(ep.[name]) = 'tsql local machine') OR(permission_name = 'CONNECT' AND perms.class = 105 AND LOWER(ep.[name]) = 'tsql named pipes') OR (permission_name = 'CONNECT' AND perms.class = 105 AND LOWER(ep.[name]) = 'tsql default tcp') OR (permission_name = 'CONNECT' AND perms.class = 105 AND LOWER(ep.[name]) = 'tsql default via') OR (permission_name = 'VIEW ANY DATABASE' AND perms.class = 100))
	ELSE
		SELECT
			@@SERVERNAME AS sql_instance,'VA1280' AS vulnerability,CONCAT('Server role [public] should have permission ',[permission_name],' revoked') AS [description]
			--,permission_name AS [permission],CASE WHEN perms.class = 101 THEN 'LOGIN' ELSE class_desc END AS [permission_class],CASE WHEN perms.class = 100 THEN @@SERVERNAME WHEN perms.class = 101 THEN prins.[name] WHEN perms.class = 105 THEN ep.[name] END AS [object]
		FROM sys.server_permissions AS perms
		LEFT JOIN sys.endpoints AS ep ON ep.endpoint_id = perms.major_id
		LEFT JOIN sys.server_principals AS prins ON prins.principal_id = perms.major_id
		WHERE grantee_principal_id = SUSER_ID('public')
			AND NOT ((permission_name = 'CONNECT' AND perms.class = 105 AND LOWER(ep.[name]) = 'tsql local machine') OR(permission_name = 'CONNECT' AND perms.class = 105 AND LOWER(ep.[name]) = 'tsql named pipes') OR (permission_name = 'CONNECT' AND perms.class = 105 AND LOWER(ep.[name]) = 'tsql default tcp') OR (permission_name = 'CONNECT' AND perms.class = 105 AND LOWER(ep.[name]) = 'tsql default via') OR (permission_name = 'VIEW ANY DATABASE' AND perms.class = 100))
 
--VA1281 / FedRAMP / All memberships for user-defined roles should be intended
	USE tempdb;
	DECLARE @va1281_sql nvarchar(2000)
	IF OBJECT_ID('tempdb.dbo.#va1281', 'U') IS NOT NULL DROP TABLE #va1281;
 
	CREATE TABLE #va1281 ([db_name] sysname, [role] sysname, [member] sysname)
 
	SET @va1281_sql='USE [?]
		INSERT INTO #va1281
		SELECT DB_NAME() AS [db_name], USER_NAME(role_principal_id) AS [role], USER_NAME(member_principal_id) AS [member]
		FROM sys.database_role_members
		WHERE role_principal_id NOT IN (16384,16385,16386,16387,16389,16390,16391,16392,16393)'
 
	exec sp_MSforeachdb @va1281_sql
 
	IF EXISTS (SELECT 1 FROM #va1281)
		SELECT @@SERVERNAME AS sql_instance, 'VA1281' AS vulnerability, CONCAT('in db ',QUOTENAME([db_name]),' role ',QUOTENAME([role]),' of login ',QUOTENAME([member]),' should be either revoked or marked as baseline') AS [description]
		--,[db_name], [role], [member]
		FROM #va1281;
	ELSE
		SELECT @@SERVERNAME AS sql_instance, 'VA1281' AS vulnerability, '' AS [description]
		--,'' AS [db_name], '' AS [role], '' AS [member]
 
	DROP TABLE #va1281;
 
--VA1282 / FedRAMP / Orphan roles should be removed
	USE tempdb;
	DECLARE @va1282_sql nvarchar(2000)
	IF OBJECT_ID('tempdb.dbo.#va1282', 'U') IS NOT NULL DROP TABLE #va1282;
 
	CREATE TABLE #va1282 ([db_name] sysname, [role] sysname)
 
	SET @va1282_sql='USE [?]
	INSERT INTO #va1282
	SELECT DB_NAME() AS [db_name],[name] AS [role]
	FROM sys.database_principals
	WHERE [type] = ''R'' AND principal_id NOT IN (0,16384,16385,16386,16387,16389,16390,16391,16392,16393) AND principal_id NOT IN (SELECT DISTINCT role_principal_id FROM sys.database_role_members)'
 
	exec sp_MSforeachdb @va1282_sql
 
	IF EXISTS (SELECT 1 FROM #va1282)
		SELECT @@SERVERNAME AS sql_instance, 'VA1282' AS vulnerability, CONCAT('in db ',QUOTENAME([db_name]),' orphaned role ',QUOTENAME([role]),' should be removed') AS [description]
		--,[db_name],[role] AS [orphaned_role]
		FROM #va1282;
	ELSE
		SELECT @@SERVERNAME AS sql_instance, 'VA1282' AS vulnerability, '' AS [description]
		--,'' AS [db_name], '' AS [orphaned_role]
 
	DROP TABLE #va1282;
 
--VA1283 / FedRAMP / There should be at least 1 active audit in the system
	IF NOT EXISTS (SELECT [name] FROM sys.server_audits WHERE is_state_enabled = 1 AND [type] != 'FL'
					UNION
					SELECT [name] FROM sys.server_file_audits WHERE is_state_enabled = 1)
		SELECT @@SERVERNAME AS sql_instance, 'VA1283' AS vulnerability, 'at least one audit should be activated' AS [description]
	ELSE
		SELECT @@SERVERNAME AS sql_instance, 'VA1283' AS vulnerability, '' AS [description]
 
--VA2020 / FedRAMP / Minimal set of principals should be granted ALTER or ALTER ANY USER database-scoped permissions
	USE tempdb;
	DECLARE @va2020_sql nvarchar(2000)
	IF OBJECT_ID('tempdb.dbo.#va2020', 'U') IS NOT NULL DROP TABLE #va2020;
 
	CREATE TABLE #va2020 ([db_name] sysname, [permission_class] sysname, [permission] sysname, [principal_type] sysname, [principal] sysname)
 
	SET @va2020_sql='USE [?]
	INSERT INTO #va2020
	SELECT DB_NAME() AS [db_name], perms.class_desc AS [permission_class],perms.permission_name AS [permission],[type_desc] AS [principal_type],prin.name AS [principal]
	FROM sys.database_permissions AS perms
	INNER JOIN sys.database_principals AS prin ON perms.grantee_principal_id = prin.principal_id
	WHERE permission_name IN (''ALTER'',''ALTER ANY USER'') AND USER_NAME(grantee_principal_id) NOT IN (''guest'',''public'') AND perms.class = 0 AND [state] IN (''G'',''W'') AND NOT (prin.type = ''S'' AND prin.name = ''dbo'' AND prin.authentication_type = 1 AND prin.owning_principal_id IS NULL )'
 
	exec sp_MSforeachdb @va2020_sql
 
	IF EXISTS (SELECT 1 FROM #va2020)
		SELECT @@SERVERNAME AS sql_instance, 'VA2020' AS vulnerability, CONCAT('permission ',QUOTENAME([permission]),' in db ',QUOTENAME([db_name]),' should be revoked from ',QUOTENAME([principal])) AS [description]
		--,[db_name],[permission_class], [permission], [principal_type], [principal]
		FROM #va2020;
	ELSE
		SELECT @@SERVERNAME AS sql_instance, 'VA2020' AS vulnerability, '' AS [description]
		--,'' AS [db_name], '' AS [permission_class], '' AS [permission], '' AS [principal_type], '' AS [principal]
 
	DROP TABLE #va2020;
 
--VA2033 / FedRAMP / Minimal set of principals should be granted database-scoped EXECUTE permission on objects or columns
	USE tempdb;
	IF OBJECT_ID('tempdb.dbo.#va2033_excludes', 'U') IS NOT NULL DROP TABLE #va2033_excludes;
	IF OBJECT_ID('tempdb.dbo.#va2033', 'U') IS NOT NULL DROP TABLE #va2033;
	DECLARE @va2033_sql nvarchar(2000);
 
	CREATE TABLE #va2033_excludes (object_name varchar(64),state_desc varchar(24),prin_name varchar(64),user_name varchar(20),prin_type char(1))
 
	CREATE TABLE #va2033 (db_name sysname,[permission_class] nvarchar(60),[schema] sysname,[object] sysname,[permission] nvarchar(128),[principal_type] nvarchar(60),[principal] nvarchar(128))
 
	INSERT INTO #va2033_excludes (object_name, state_desc, prin_name, user_name, prin_type)
	VALUES ('sp_add_job', 'DENY', 'TargetServersRole', 'dbo', 'R')
		,('sp_add_jobschedule', 'DENY', 'TargetServersRole', 'dbo', 'R')
		,('sp_add_jobserver', 'DENY', 'TargetServersRole', 'dbo', 'R')
		,('sp_add_jobstep', 'DENY', 'TargetServersRole', 'dbo', 'R')
		,('sp_addtask', 'DENY', 'TargetServersRole', 'dbo', 'R')
		,('sp_delete_job', 'DENY', 'TargetServersRole', 'dbo', 'R')
		,('sp_delete_jobschedule', 'DENY', 'TargetServersRole', 'dbo', 'R')
		,('sp_delete_jobserver', 'DENY', 'TargetServersRole', 'dbo', 'R')
		,('sp_delete_jobstep', 'DENY', 'TargetServersRole', 'dbo', 'R')
		,('sp_droptask', 'DENY', 'TargetServersRole', 'dbo', 'R')
		,('sp_post_msx_operation', 'DENY', 'TargetServersRole', 'dbo', 'R')
		,('sp_start_job', 'DENY', 'TargetServersRole', 'dbo', 'R')
		,('sp_stop_job', 'DENY', 'TargetServersRole', 'dbo', 'R')
		,('sp_update_job', 'DENY', 'TargetServersRole', 'dbo', 'R')
		,('sp_update_jobschedule', 'DENY', 'TargetServersRole', 'dbo', 'R')
		,('sp_update_jobstep', 'DENY', 'TargetServersRole', 'dbo', 'R')
		,('sp_syspolicy_events_reader', 'GRANT', '##MS_PolicyEventProcessingLogin##', 'dbo', 'S')
		,('sp_syspolicy_execute_policy', 'GRANT', '##MS_PolicyEventProcessingLogin##', 'dbo', 'S')
		,('fn_cColvEntries_80', 'GRANT', 'public', 'dbo', 'R')
		,('fn_cdc_check_parameters', 'GRANT', 'public', 'dbo', 'R')
		,('fn_cdc_decrement_lsn', 'GRANT', 'public', 'dbo', 'R')
		,('fn_cdc_get_column_ordinal', 'GRANT', 'public', 'dbo', 'R')
		,('fn_cdc_get_max_lsn', 'GRANT', 'public', 'dbo', 'R')
		,('fn_cdc_get_min_lsn', 'GRANT', 'public', 'dbo', 'R')
		,('fn_cdc_has_column_changed', 'GRANT', 'public', 'dbo', 'R')
		,('fn_cdc_hexstrtobin', 'GRANT', 'public', 'dbo', 'R')
		,('fn_cdc_increment_lsn', 'GRANT', 'public', 'dbo', 'R')
		,('fn_cdc_is_bit_set', 'GRANT', 'public', 'dbo', 'R')
		,('fn_cdc_map_lsn_to_time', 'GRANT', 'public', 'dbo', 'R')
		,('fn_cdc_map_time_to_lsn', 'GRANT', 'public', 'dbo', 'R')
		,('fn_fIsColTracked', 'GRANT', 'public', 'dbo', 'R')
		,('fn_GetCurrentPrincipal', 'GRANT', 'public', 'dbo', 'R')
		,('fn_GetRowsetIdFromRowDump', 'GRANT', 'public', 'dbo', 'R')
		,('fn_hadr_backup_is_preferred_replica', 'GRANT', 'public', 'dbo', 'R')
		,('fn_hadr_is_primary_replica', 'GRANT', 'public', 'dbo', 'R')
		,('fn_hadr_is_same_replica', 'GRANT', 'public', 'dbo', 'R')
		,('fn_IsBitSetInBitmask', 'GRANT', 'public', 'dbo', 'R')
		,('fn_isrolemember', 'GRANT', 'public', 'dbo', 'R')
		,('fn_MapSchemaType', 'GRANT', 'public', 'dbo', 'R')
		,('fn_MSdayasnumber', 'GRANT', 'public', 'dbo', 'R')
		,('fn_MSgeneration_downloadonly', 'GRANT', 'public', 'dbo', 'R')
		,('fn_MSget_dynamic_filter_login', 'GRANT', 'public', 'dbo', 'R')
		,('fn_MSorbitmaps', 'GRANT', 'public', 'dbo', 'R')
		,('fn_MSrepl_map_resolver_clsid', 'GRANT', 'public', 'dbo', 'R')
		,('fn_MStestbit', 'GRANT', 'public', 'dbo', 'R')
		,('fn_MSvector_downloadonly', 'GRANT', 'public', 'dbo', 'R')
		,('fn_numberOf1InBinaryAfterLoc', 'GRANT', 'public', 'dbo', 'R')
		,('fn_numberOf1InVarBinary', 'GRANT', 'public', 'dbo', 'R')
		,('fn_PhysLocFormatter', 'GRANT', 'public', 'dbo', 'R')
		,('fn_repl_hash_binary', 'GRANT', 'public', 'dbo', 'R')
		,('fn_repladjustcolumnmap', 'GRANT', 'public', 'dbo', 'R')
		,('fn_repldecryptver4', 'GRANT', 'public', 'dbo', 'R')
		,('fn_replformatdatetime', 'GRANT', 'public', 'dbo', 'R')
		,('fn_replgetparsedddlcmd', 'GRANT', 'public', 'dbo', 'R')
		,('fn_replp2pversiontotranid', 'GRANT', 'public', 'dbo', 'R')
		,('fn_replreplacesinglequote', 'GRANT', 'public', 'dbo', 'R')
		,('fn_replreplacesinglequoteplusprotectstring', 'GRANT', 'public', 'dbo', 'R')
		,('fn_repluniquename', 'GRANT', 'public', 'dbo', 'R')
		,('fn_replvarbintoint', 'GRANT', 'public', 'dbo', 'R')
		,('fn_sqlvarbasetostr', 'GRANT', 'public', 'dbo', 'R')
		,('fn_sysdac_get_currentusername', 'GRANT', 'public', 'dbo', 'R')
		,('fn_sysdac_get_username', 'GRANT', 'public', 'dbo', 'R')
		,('fn_sysdac_is_currentuser_sa', 'GRANT', 'public', 'dbo', 'R')
		,('fn_sysdac_is_dac_creator', 'GRANT', 'public', 'dbo', 'R')
		,('fn_sysdac_is_login_creator', 'GRANT', 'public', 'dbo', 'R')
		,('fn_syspolicy_is_automation_enabled', 'GRANT', 'public', 'dbo', 'R')
		,('fn_varbintohexstr', 'GRANT', 'public', 'dbo', 'R')
		,('fn_varbintohexsubstring', 'GRANT', 'public', 'dbo', 'R')
		,('fn_yukonsecuritymodelrequired', 'GRANT', 'public', 'dbo', 'R')
		,('GeographyCollectionAggregate', 'GRANT', 'public', 'dbo', 'R')
		,('GeographyConvexHullAggregate', 'GRANT', 'public', 'dbo', 'R')
		,('GeographyEnvelopeAggregate', 'GRANT', 'public', 'dbo', 'R')
		,('GeographyUnionAggregate', 'GRANT', 'public', 'dbo', 'R')
		,('GeometryCollectionAggregate', 'GRANT', 'public', 'dbo', 'R')
		,('GeometryConvexHullAggregate', 'GRANT', 'public', 'dbo', 'R')
		,('GeometryEnvelopeAggregate', 'GRANT', 'public', 'dbo', 'R')
		,('GeometryUnionAggregate', 'GRANT', 'public', 'dbo', 'R')
		,('ORMask', 'GRANT', 'public', 'dbo', 'R')
		,('sp_add_agent_parameter', 'GRANT', 'public', 'dbo', 'R')
		,('sp_add_agent_profile', 'GRANT', 'public', 'dbo', 'R')
		,('sp_add_log_shipping_alert_job', 'GRANT', 'public', 'dbo', 'R')
		,('sp_add_log_shipping_primary_database', 'GRANT', 'public', 'dbo', 'R')
		,('sp_add_log_shipping_primary_secondary', 'GRANT', 'public', 'dbo', 'R')
		,('sp_add_log_shipping_secondary_database', 'GRANT', 'public', 'dbo', 'R')
		,('sp_add_log_shipping_secondary_primary', 'GRANT', 'public', 'dbo', 'R')
		,('sp_addapprole', 'GRANT', 'public', 'dbo', 'R')
		,('sp_addarticle', 'GRANT', 'public', 'dbo', 'R')
		,('sp_adddatatype', 'GRANT', 'public', 'dbo', 'R')
		,('sp_adddatatypemapping', 'GRANT', 'public', 'dbo', 'R')
		,('sp_adddistpublisher', 'GRANT', 'public', 'dbo', 'R')
		,('sp_adddistributiondb', 'GRANT', 'public', 'dbo', 'R')
		,('sp_adddistributor', 'GRANT', 'public', 'dbo', 'R')
		,('sp_adddynamicsnapshot_job', 'GRANT', 'public', 'dbo', 'R')
		,('sp_addextendedproperty', 'GRANT', 'public', 'dbo', 'R')
		,('sp_AddFunctionalUnitToComponent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_addlinkedserver', 'GRANT', 'public', 'dbo', 'R')
		,('sp_addlinkedsrvlogin', 'GRANT', 'public', 'dbo', 'R')
		,('sp_addlogin', 'GRANT', 'public', 'dbo', 'R')
		,('sp_addlogreader_agent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_addmergealternatepublisher', 'GRANT', 'public', 'dbo', 'R')
		,('sp_addmergearticle', 'GRANT', 'public', 'dbo', 'R')
		,('sp_addmergefilter', 'GRANT', 'public', 'dbo', 'R')
		,('sp_addmergelogsettings', 'GRANT', 'public', 'dbo', 'R')
		,('sp_addmergepartition', 'GRANT', 'public', 'dbo', 'R')
		,('sp_addmergepublication', 'GRANT', 'public', 'dbo', 'R')
		,('sp_addmergepullsubscription', 'GRANT', 'public', 'dbo', 'R')
		,('sp_addmergepullsubscription_agent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_addmergepushsubscription_agent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_addmergesubscription', 'GRANT', 'public', 'dbo', 'R')
		,('sp_addmessage', 'GRANT', 'public', 'dbo', 'R')
		,('sp_addpublication', 'GRANT', 'public', 'dbo', 'R')
		,('sp_addpublication_snapshot', 'GRANT', 'public', 'dbo', 'R')
		,('sp_addpullsubscription', 'GRANT', 'public', 'dbo', 'R')
		,('sp_addpullsubscription_agent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_addpushsubscription_agent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_addqreader_agent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_addqueued_artinfo', 'GRANT', 'public', 'dbo', 'R')
		,('sp_addremotelogin', 'GRANT', 'public', 'dbo', 'R')
		,('sp_addrole', 'GRANT', 'public', 'dbo', 'R')
		,('sp_addrolemember', 'GRANT', 'public', 'dbo', 'R')
		,('sp_addscriptexec', 'GRANT', 'public', 'dbo', 'R')
		,('sp_addserver', 'GRANT', 'public', 'dbo', 'R')
		,('sp_addsrvrolemember', 'GRANT', 'public', 'dbo', 'R')
		,('sp_addsubscriber', 'GRANT', 'public', 'dbo', 'R')
		,('sp_addsubscriber_schedule', 'GRANT', 'public', 'dbo', 'R')
		,('sp_addsubscription', 'GRANT', 'public', 'dbo', 'R')
		,('sp_addsynctriggers', 'GRANT', 'public', 'dbo', 'R')
		,('sp_addsynctriggerscore', 'GRANT', 'public', 'dbo', 'R')
		,('sp_addtabletocontents', 'GRANT', 'public', 'dbo', 'R')
		,('sp_addtype', 'GRANT', 'public', 'dbo', 'R')
		,('sp_addumpdevice', 'GRANT', 'public', 'dbo', 'R')
		,('sp_adduser', 'GRANT', 'public', 'dbo', 'R')
		,('sp_adjustpublisheridentityrange', 'GRANT', 'public', 'dbo', 'R')
		,('sp_altermessage', 'GRANT', 'public', 'dbo', 'R')
		,('sp_approlepassword', 'GRANT', 'public', 'dbo', 'R')
		,('sp_article_validation', 'GRANT', 'public', 'dbo', 'R')
		,('sp_articlecolumn', 'GRANT', 'public', 'dbo', 'R')
		,('sp_articlefilter', 'GRANT', 'public', 'dbo', 'R')
		,('sp_articleview', 'GRANT', 'public', 'dbo', 'R')
		,('sp_assemblies_rowset', 'GRANT', 'public', 'dbo', 'R')
		,('sp_assemblies_rowset_rmt', 'GRANT', 'public', 'dbo', 'R')
		,('sp_assemblies_rowset2', 'GRANT', 'public', 'dbo', 'R')
		,('sp_assembly_dependencies_rowset', 'GRANT', 'public', 'dbo', 'R')
		,('sp_assembly_dependencies_rowset_rmt', 'GRANT', 'public', 'dbo', 'R')
		,('sp_assembly_dependencies_rowset2', 'GRANT', 'public', 'dbo', 'R')
		,('sp_attach_db', 'GRANT', 'public', 'dbo', 'R')
		,('sp_attach_single_file_db', 'GRANT', 'public', 'dbo', 'R')
		,('sp_attachsubscription', 'GRANT', 'public', 'dbo', 'R')
		,('sp_audit_write', 'GRANT', 'public', 'dbo', 'R')
		,('sp_autostats', 'GRANT', 'public', 'dbo', 'R')
		,('sp_availability_group_command_internal', 'GRANT', 'public', 'dbo', 'R')
		,('sp_bcp_dbcmptlevel', 'GRANT', 'public', 'dbo', 'R')
		,('sp_begin_parallel_nested_tran', 'GRANT', 'public', 'dbo', 'R')
		,('sp_bindefault', 'GRANT', 'public', 'dbo', 'R')
		,('sp_bindrule', 'GRANT', 'public', 'dbo', 'R')
		,('sp_bindsession', 'GRANT', 'public', 'dbo', 'R')
		,('sp_browsemergesnapshotfolder', 'GRANT', 'public', 'dbo', 'R')
		,('sp_browsereplcmds', 'GRANT', 'public', 'dbo', 'R')
		,('sp_browsesnapshotfolder', 'GRANT', 'public', 'dbo', 'R')
		,('sp_can_tlog_be_applied', 'GRANT', 'public', 'dbo', 'R')
		,('sp_catalogs', 'GRANT', 'public', 'dbo', 'R')
		,('sp_catalogs_rowset', 'GRANT', 'public', 'dbo', 'R')
		,('sp_catalogs_rowset_rmt', 'GRANT', 'public', 'dbo', 'R')
		,('sp_catalogs_rowset2', 'GRANT', 'public', 'dbo', 'R')
		,('sp_cdc_add_job', 'GRANT', 'public', 'dbo', 'R')
		,('sp_cdc_change_job', 'GRANT', 'public', 'dbo', 'R')
		,('sp_cdc_cleanup_change_table', 'GRANT', 'public', 'dbo', 'R')
		,('sp_cdc_dbsnapshotLSN', 'GRANT', 'public', 'dbo', 'R')
		,('sp_cdc_disable_db', 'GRANT', 'public', 'dbo', 'R')
		,('sp_cdc_disable_table', 'GRANT', 'public', 'dbo', 'R')
		,('sp_cdc_drop_job', 'GRANT', 'public', 'dbo', 'R')
		,('sp_cdc_enable_db', 'GRANT', 'public', 'dbo', 'R')
		,('sp_cdc_enable_table', 'GRANT', 'public', 'dbo', 'R')
		,('sp_cdc_generate_wrapper_function', 'GRANT', 'public', 'dbo', 'R')
		,('sp_cdc_get_captured_columns', 'GRANT', 'public', 'dbo', 'R')
		,('sp_cdc_get_ddl_history', 'GRANT', 'public', 'dbo', 'R')
		,('sp_cdc_help_change_data_capture', 'GRANT', 'public', 'dbo', 'R')
		,('sp_cdc_help_jobs', 'GRANT', 'public', 'dbo', 'R')
		,('sp_cdc_restoredb', 'GRANT', 'public', 'dbo', 'R')
		,('sp_cdc_scan', 'GRANT', 'public', 'dbo', 'R')
		,('sp_cdc_start_job', 'GRANT', 'public', 'dbo', 'R')
		,('sp_cdc_stop_job', 'GRANT', 'public', 'dbo', 'R')
		,('sp_cdc_vupgrade', 'GRANT', 'public', 'dbo', 'R')
		,('sp_cdc_vupgrade_databases', 'GRANT', 'public', 'dbo', 'R')
		,('sp_change_agent_parameter', 'GRANT', 'public', 'dbo', 'R')
		,('sp_change_agent_profile', 'GRANT', 'public', 'dbo', 'R')
		,('sp_change_log_shipping_primary_database', 'GRANT', 'public', 'dbo', 'R')
		,('sp_change_log_shipping_secondary_database', 'GRANT', 'public', 'dbo', 'R')
		,('sp_change_log_shipping_secondary_primary', 'GRANT', 'public', 'dbo', 'R')
		,('sp_change_subscription_properties', 'GRANT', 'public', 'dbo', 'R')
		,('sp_change_tracking_waitforchanges', 'GRANT', 'public', 'dbo', 'R')
		,('sp_change_users_login', 'GRANT', 'public', 'dbo', 'R')
		,('sp_changearticle', 'GRANT', 'public', 'dbo', 'R')
		,('sp_changearticlecolumndatatype', 'GRANT', 'public', 'dbo', 'R')
		,('sp_changedbowner', 'GRANT', 'public', 'dbo', 'R')
		,('sp_changedistpublisher', 'GRANT', 'public', 'dbo', 'R')
		,('sp_changedistributiondb', 'GRANT', 'public', 'dbo', 'R')
		,('sp_changedistributor_password', 'GRANT', 'public', 'dbo', 'R')
		,('sp_changedistributor_property', 'GRANT', 'public', 'dbo', 'R')
		,('sp_changedynamicsnapshot_job', 'GRANT', 'public', 'dbo', 'R')
		,('sp_changelogreader_agent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_changemergearticle', 'GRANT', 'public', 'dbo', 'R')
		,('sp_changemergefilter', 'GRANT', 'public', 'dbo', 'R')
		,('sp_changemergelogsettings', 'GRANT', 'public', 'dbo', 'R')
		,('sp_changemergepublication', 'GRANT', 'public', 'dbo', 'R')
		,('sp_changemergepullsubscription', 'GRANT', 'public', 'dbo', 'R')
		,('sp_changemergesubscription', 'GRANT', 'public', 'dbo', 'R')
		,('sp_changeobjectowner', 'GRANT', 'public', 'dbo', 'R')
		,('sp_changepublication', 'GRANT', 'public', 'dbo', 'R')
		,('sp_changepublication_snapshot', 'GRANT', 'public', 'dbo', 'R')
		,('sp_changeqreader_agent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_changereplicationserverpasswords', 'GRANT', 'public', 'dbo', 'R')
		,('sp_changesubscriber', 'GRANT', 'public', 'dbo', 'R')
		,('sp_changesubscriber_schedule', 'GRANT', 'public', 'dbo', 'R')
		,('sp_changesubscription', 'GRANT', 'public', 'dbo', 'R')
		,('sp_changesubscriptiondtsinfo', 'GRANT', 'public', 'dbo', 'R')
		,('sp_changesubstatus', 'GRANT', 'public', 'dbo', 'R')
		,('sp_check_constbytable_rowset', 'GRANT', 'public', 'dbo', 'R')
		,('sp_check_constbytable_rowset2', 'GRANT', 'public', 'dbo', 'R')
		,('sp_check_constraints_rowset', 'GRANT', 'public', 'dbo', 'R')
		,('sp_check_constraints_rowset2', 'GRANT', 'public', 'dbo', 'R')
		,('sp_check_dynamic_filters', 'GRANT', 'public', 'dbo', 'R')
		,('sp_check_for_sync_trigger', 'GRANT', 'public', 'dbo', 'R')
		,('sp_check_join_filter', 'GRANT', 'public', 'dbo', 'R')
		,('sp_check_log_shipping_monitor_alert', 'GRANT', 'public', 'dbo', 'R')
		,('sp_check_publication_access', 'GRANT', 'public', 'dbo', 'R')
		,('sp_check_subset_filter', 'GRANT', 'public', 'dbo', 'R')
		,('sp_check_sync_trigger', 'GRANT', 'public', 'dbo', 'R')
		,('sp_checkinvalidivarticle', 'GRANT', 'public', 'dbo', 'R')
		,('sp_checkOraclepackageversion', 'GRANT', 'public', 'dbo', 'R')
		,('sp_clean_db_file_free_space', 'GRANT', 'public', 'dbo', 'R')
		,('sp_clean_db_free_space', 'GRANT', 'public', 'dbo', 'R')
		,('sp_cleanmergelogfiles', 'GRANT', 'public', 'dbo', 'R')
		,('sp_cleanup_log_shipping_history', 'GRANT', 'public', 'dbo', 'R')
		,('sp_cleanup_temporal_history', 'GRANT', 'public', 'dbo', 'R')
		,('sp_cleanupdbreplication', 'GRANT', 'public', 'dbo', 'R')
		,('sp_column_privileges', 'GRANT', 'public', 'dbo', 'R')
		,('sp_column_privileges_ex', 'GRANT', 'public', 'dbo', 'R')
		,('sp_column_privileges_rowset', 'GRANT', 'public', 'dbo', 'R')
		,('sp_column_privileges_rowset_rmt', 'GRANT', 'public', 'dbo', 'R')
		,('sp_column_privileges_rowset2', 'GRANT', 'public', 'dbo', 'R')
		,('sp_columns', 'GRANT', 'public', 'dbo', 'R')
		,('sp_columns_100', 'GRANT', 'public', 'dbo', 'R')
		,('sp_columns_100_rowset', 'GRANT', 'public', 'dbo', 'R')
		,('sp_columns_100_rowset2', 'GRANT', 'public', 'dbo', 'R')
		,('sp_columns_90', 'GRANT', 'public', 'dbo', 'R')
		,('sp_columns_90_rowset', 'GRANT', 'public', 'dbo', 'R')
		,('sp_columns_90_rowset_rmt', 'GRANT', 'public', 'dbo', 'R')
		,('sp_columns_90_rowset2', 'GRANT', 'public', 'dbo', 'R')
		,('sp_columns_ex', 'GRANT', 'public', 'dbo', 'R')
		,('sp_columns_ex_100', 'GRANT', 'public', 'dbo', 'R')
		,('sp_columns_ex_90', 'GRANT', 'public', 'dbo', 'R')
		,('sp_columns_managed', 'GRANT', 'public', 'dbo', 'R')
		,('sp_columns_rowset', 'GRANT', 'public', 'dbo', 'R')
		,('sp_columns_rowset_rmt', 'GRANT', 'public', 'dbo', 'R')
		,('sp_columns_rowset2', 'GRANT', 'public', 'dbo', 'R')
		,('sp_commit_parallel_nested_tran', 'GRANT', 'public', 'dbo', 'R')
		,('sp_configure', 'GRANT', 'public', 'dbo', 'R')
		,('sp_configure_peerconflictdetection', 'GRANT', 'public', 'dbo', 'R')
		,('sp_constr_col_usage_rowset', 'GRANT', 'public', 'dbo', 'R')
		,('sp_constr_col_usage_rowset2', 'GRANT', 'public', 'dbo', 'R')
		,('sp_control_dbmasterkey_password', 'GRANT', 'public', 'dbo', 'R')
		,('sp_control_plan_guide', 'GRANT', 'public', 'dbo', 'R')
		,('sp_copymergesnapshot', 'GRANT', 'public', 'dbo', 'R')
		,('sp_copysnapshot', 'GRANT', 'public', 'dbo', 'R')
		,('sp_copysubscription', 'GRANT', 'public', 'dbo', 'R')
		,('sp_create_plan_guide', 'GRANT', 'public', 'dbo', 'R')
		,('sp_create_plan_guide_from_handle', 'GRANT', 'public', 'dbo', 'R')
		,('sp_createmergepalrole', 'GRANT', 'public', 'dbo', 'R')
		,('sp_createorphan', 'GRANT', 'public', 'dbo', 'R')
		,('sp_createstats', 'GRANT', 'public', 'dbo', 'R')
		,('sp_createtranpalrole', 'GRANT', 'public', 'dbo', 'R')
		,('sp_cursor', 'GRANT', 'public', 'dbo', 'R')
		,('sp_cursor_list', 'GRANT', 'public', 'dbo', 'R')
		,('sp_cursorclose', 'GRANT', 'public', 'dbo', 'R')
		,('sp_cursorexecute', 'GRANT', 'public', 'dbo', 'R')
		,('sp_cursorfetch', 'GRANT', 'public', 'dbo', 'R')
		,('sp_cursoropen', 'GRANT', 'public', 'dbo', 'R')
		,('sp_cursoroption', 'GRANT', 'public', 'dbo', 'R')
		,('sp_cursorprepare', 'GRANT', 'public', 'dbo', 'R')
		,('sp_cursorprepexec', 'GRANT', 'public', 'dbo', 'R')
		,('sp_cursorunprepare', 'GRANT', 'public', 'dbo', 'R')
		,('sp_databases', 'GRANT', 'public', 'dbo', 'R')
		,('sp_datatype_info', 'GRANT', 'public', 'dbo', 'R')
		,('sp_datatype_info_100', 'GRANT', 'public', 'dbo', 'R')
		,('sp_datatype_info_90', 'GRANT', 'public', 'dbo', 'R')
		,('sp_db_ebcdic277_2', 'GRANT', 'public', 'dbo', 'R')
		,('sp_db_increased_partitions', 'GRANT', 'public', 'dbo', 'R')
		,('sp_db_selective_xml_index', 'GRANT', 'public', 'dbo', 'R')
		,('sp_db_vardecimal_storage_format', 'GRANT', 'public', 'dbo', 'R')
		,('sp_dbcmptlevel', 'GRANT', 'public', 'dbo', 'R')
		,('sp_dbfixedrolepermission', 'GRANT', 'public', 'dbo', 'R')
		,('sp_dbmmonitoraddmonitoring', 'GRANT', 'public', 'dbo', 'R')
		,('sp_dbmmonitorchangealert', 'GRANT', 'public', 'dbo', 'R')
		,('sp_dbmmonitorchangemonitoring', 'GRANT', 'public', 'dbo', 'R')
		,('sp_dbmmonitordropalert', 'GRANT', 'public', 'dbo', 'R')
		,('sp_dbmmonitordropmonitoring', 'GRANT', 'public', 'dbo', 'R')
		,('sp_dbmmonitorhelpalert', 'GRANT', 'public', 'dbo', 'R')
		,('sp_dbmmonitorhelpmonitoring', 'GRANT', 'public', 'dbo', 'R')
		,('sp_dbmmonitorresults', 'GRANT', 'public', 'dbo', 'R')
		,('sp_dbmmonitorupdate', 'GRANT', 'public', 'dbo', 'R')
		,('sp_ddopen', 'GRANT', 'public', 'dbo', 'R')
		,('sp_defaultdb', 'GRANT', 'public', 'dbo', 'R')
		,('sp_defaultlanguage', 'GRANT', 'public', 'dbo', 'R')
		,('sp_delete_backup', 'GRANT', 'public', 'dbo', 'R')
		,('sp_delete_backup_file_snapshot', 'GRANT', 'public', 'dbo', 'R')
		,('sp_delete_http_namespace_reservation', 'GRANT', 'public', 'dbo', 'R')
		,('sp_delete_log_shipping_alert_job', 'GRANT', 'public', 'dbo', 'R')
		,('sp_delete_log_shipping_primary_database', 'GRANT', 'public', 'dbo', 'R')
		,('sp_delete_log_shipping_primary_secondary', 'GRANT', 'public', 'dbo', 'R')
		,('sp_delete_log_shipping_secondary_database', 'GRANT', 'public', 'dbo', 'R')
		,('sp_delete_log_shipping_secondary_primary', 'GRANT', 'public', 'dbo', 'R')
		,('sp_deletemergeconflictrow', 'GRANT', 'public', 'dbo', 'R')
		,('sp_deletepeerrequesthistory', 'GRANT', 'public', 'dbo', 'R')
		,('sp_deletetracertokenhistory', 'GRANT', 'public', 'dbo', 'R')
		,('sp_denylogin', 'GRANT', 'public', 'dbo', 'R')
		,('sp_depends', 'GRANT', 'public', 'dbo', 'R')
		,('sp_describe_cursor', 'GRANT', 'public', 'dbo', 'R')
		,('sp_describe_cursor_columns', 'GRANT', 'public', 'dbo', 'R')
		,('sp_describe_cursor_tables', 'GRANT', 'public', 'dbo', 'R')
		,('sp_describe_first_result_set', 'GRANT', 'public', 'dbo', 'R')
		,('sp_describe_parameter_encryption', 'GRANT', 'public', 'dbo', 'R')
		,('sp_describe_undeclared_parameters', 'GRANT', 'public', 'dbo', 'R')
		,('sp_detach_db', 'GRANT', 'public', 'dbo', 'R')
		,('sp_disableagentoffload', 'GRANT', 'public', 'dbo', 'R')
		,('sp_distcounters', 'GRANT', 'public', 'dbo', 'R')
		,('sp_drop_agent_parameter', 'GRANT', 'public', 'dbo', 'R')
		,('sp_drop_agent_profile', 'GRANT', 'public', 'dbo', 'R')
		,('sp_dropanonymousagent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_dropanonymoussubscription', 'GRANT', 'public', 'dbo', 'R')
		,('sp_dropapprole', 'GRANT', 'public', 'dbo', 'R')
		,('sp_droparticle', 'GRANT', 'public', 'dbo', 'R')
		,('sp_dropdatatypemapping', 'GRANT', 'public', 'dbo', 'R')
		,('sp_dropdevice', 'GRANT', 'public', 'dbo', 'R')
		,('sp_dropdistpublisher', 'GRANT', 'public', 'dbo', 'R')
		,('sp_dropdistributiondb', 'GRANT', 'public', 'dbo', 'R')
		,('sp_dropdistributor', 'GRANT', 'public', 'dbo', 'R')
		,('sp_dropdynamicsnapshot_job', 'GRANT', 'public', 'dbo', 'R')
		,('sp_dropextendedproperty', 'GRANT', 'public', 'dbo', 'R')
		,('sp_droplinkedsrvlogin', 'GRANT', 'public', 'dbo', 'R')
		,('sp_droplogin', 'GRANT', 'public', 'dbo', 'R')
		,('sp_dropmergealternatepublisher', 'GRANT', 'public', 'dbo', 'R')
		,('sp_dropmergearticle', 'GRANT', 'public', 'dbo', 'R')
		,('sp_dropmergefilter', 'GRANT', 'public', 'dbo', 'R')
		,('sp_dropmergelogsettings', 'GRANT', 'public', 'dbo', 'R')
		,('sp_dropmergepartition', 'GRANT', 'public', 'dbo', 'R')
		,('sp_dropmergepublication', 'GRANT', 'public', 'dbo', 'R')
		,('sp_dropmergepullsubscription', 'GRANT', 'public', 'dbo', 'R')
		,('sp_dropmergesubscription', 'GRANT', 'public', 'dbo', 'R')
		,('sp_dropmessage', 'GRANT', 'public', 'dbo', 'R')
		,('sp_droporphans', 'GRANT', 'public', 'dbo', 'R')
		,('sp_droppublication', 'GRANT', 'public', 'dbo', 'R')
		,('sp_droppublisher', 'GRANT', 'public', 'dbo', 'R')
		,('sp_droppullsubscription', 'GRANT', 'public', 'dbo', 'R')
		,('sp_dropremotelogin', 'GRANT', 'public', 'dbo', 'R')
		,('sp_dropreplsymmetrickey', 'GRANT', 'public', 'dbo', 'R')
		,('sp_droprole', 'GRANT', 'public', 'dbo', 'R')
		,('sp_droprolemember', 'GRANT', 'public', 'dbo', 'R')
		,('sp_dropserver', 'GRANT', 'public', 'dbo', 'R')
		,('sp_dropsrvrolemember', 'GRANT', 'public', 'dbo', 'R')
		,('sp_dropsubscriber', 'GRANT', 'public', 'dbo', 'R')
		,('sp_dropsubscription', 'GRANT', 'public', 'dbo', 'R')
		,('sp_droptype', 'GRANT', 'public', 'dbo', 'R')
		,('sp_dropuser', 'GRANT', 'public', 'dbo', 'R')
		,('sp_dsninfo', 'GRANT', 'public', 'dbo', 'R')
		,('sp_enable_heterogeneous_subscription', 'GRANT', 'public', 'dbo', 'R')
		,('sp_enableagentoffload', 'GRANT', 'public', 'dbo', 'R')
		,('sp_enum_oledb_providers', 'GRANT', 'public', 'dbo', 'R')
		,('sp_enumcustomresolvers', 'GRANT', 'public', 'dbo', 'R')
		,('sp_enumdsn', 'GRANT', 'public', 'dbo', 'R')
		,('sp_enumeratependingschemachanges', 'GRANT', 'public', 'dbo', 'R')
		,('sp_enumerrorlogs', 'GRANT', 'public', 'dbo', 'R')
		,('sp_enumfullsubscribers', 'GRANT', 'public', 'dbo', 'R')
		,('sp_enumoledbdatasources', 'GRANT', 'public', 'dbo', 'R')
		,('sp_estimate_data_compression_savings', 'GRANT', 'public', 'dbo', 'R')
		,('sp_estimated_rowsize_reduction_for_vardecimal', 'GRANT', 'public', 'dbo', 'R')
		,('sp_execute', 'GRANT', 'public', 'dbo', 'R')
		,('sp_execute_external_script', 'GRANT', 'public', 'dbo', 'R')
		,('sp_executesql', 'GRANT', 'public', 'dbo', 'R')
		,('sp_expired_subscription_cleanup', 'GRANT', 'public', 'dbo', 'R')
		,('sp_filestream_force_garbage_collection', 'GRANT', 'public', 'dbo', 'R')
		,('sp_filestream_recalculate_container_size', 'GRANT', 'public', 'dbo', 'R')
		,('sp_firstonly_bitmap', 'GRANT', 'public', 'dbo', 'R')
		,('sp_fkeys', 'GRANT', 'public', 'dbo', 'R')
		,('sp_flush_commit_table', 'GRANT', 'public', 'dbo', 'R')
		,('sp_flush_commit_table_on_demand', 'GRANT', 'public', 'dbo', 'R')
		,('sp_flush_CT_internal_table_on_demand', 'GRANT', 'public', 'dbo', 'R')
		,('sp_flush_log', 'GRANT', 'public', 'dbo', 'R')
		,('sp_foreign_keys_rowset', 'GRANT', 'public', 'dbo', 'R')
		,('sp_foreign_keys_rowset_rmt', 'GRANT', 'public', 'dbo', 'R')
		,('sp_foreign_keys_rowset2', 'GRANT', 'public', 'dbo', 'R')
		,('sp_foreign_keys_rowset3', 'GRANT', 'public', 'dbo', 'R')
		,('sp_foreignkeys', 'GRANT', 'public', 'dbo', 'R')
		,('sp_fulltext_catalog', 'GRANT', 'public', 'dbo', 'R')
		,('sp_fulltext_column', 'GRANT', 'public', 'dbo', 'R')
		,('sp_fulltext_database', 'GRANT', 'public', 'dbo', 'R')
		,('sp_fulltext_keymappings', 'GRANT', 'public', 'dbo', 'R')
		,('sp_fulltext_load_thesaurus_file', 'GRANT', 'public', 'dbo', 'R')
		,('sp_fulltext_pendingchanges', 'GRANT', 'public', 'dbo', 'R')
		,('sp_fulltext_recycle_crawl_log', 'GRANT', 'public', 'dbo', 'R')
		,('sp_fulltext_semantic_register_language_statistics_db', 'GRANT', 'public', 'dbo', 'R')
		,('sp_fulltext_semantic_unregister_language_statistics_db', 'GRANT', 'public', 'dbo', 'R')
		,('sp_fulltext_service', 'GRANT', 'public', 'dbo', 'R')
		,('sp_fulltext_table', 'GRANT', 'public', 'dbo', 'R')
		,('sp_FuzzyLookupTableMaintenanceInstall', 'GRANT', 'public', 'dbo', 'R')
		,('sp_FuzzyLookupTableMaintenanceInvoke', 'GRANT', 'public', 'dbo', 'R')
		,('sp_FuzzyLookupTableMaintenanceUninstall', 'GRANT', 'public', 'dbo', 'R')
		,('sp_generate_agent_parameter', 'GRANT', 'public', 'dbo', 'R')
		,('sp_generatefilters', 'GRANT', 'public', 'dbo', 'R')
		,('sp_get_database_scoped_credential', 'GRANT', 'public', 'dbo', 'R')
		,('sp_get_distributor', 'GRANT', 'public', 'dbo', 'R')
		,('sp_get_job_status_mergesubscription_agent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_get_mergepublishedarticleproperties', 'GRANT', 'public', 'dbo', 'R')
		,('sp_get_Oracle_publisher_metadata', 'GRANT', 'public', 'dbo', 'R')
		,('sp_get_query_template', 'GRANT', 'public', 'dbo', 'R')
		,('sp_get_redirected_publisher', 'GRANT', 'public', 'dbo', 'R')
		,('sp_getagentparameterlist', 'GRANT', 'public', 'dbo', 'R')
		,('sp_getapplock', 'GRANT', 'public', 'dbo', 'R')
		,('sp_getbindtoken', 'GRANT', 'public', 'dbo', 'R')
		,('sp_getdefaultdatatypemapping', 'GRANT', 'public', 'dbo', 'R')
		,('sp_getmergedeletetype', 'GRANT', 'public', 'dbo', 'R')
		,('sp_getProcessorUsage', 'GRANT', 'public', 'dbo', 'R')
		,('sp_getpublisherlink', 'GRANT', 'public', 'dbo', 'R')
		,('sp_getqueuedarticlesynctraninfo', 'GRANT', 'public', 'dbo', 'R')
		,('sp_getqueuedrows', 'GRANT', 'public', 'dbo', 'R')
		,('sp_getschemalock', 'GRANT', 'public', 'dbo', 'R')
		,('sp_getsqlqueueversion', 'GRANT', 'public', 'dbo', 'R')
		,('sp_getsubscription_status_hsnapshot', 'GRANT', 'public', 'dbo', 'R')
		,('sp_getsubscriptiondtspackagename', 'GRANT', 'public', 'dbo', 'R')
		,('sp_gettopologyinfo', 'GRANT', 'public', 'dbo', 'R')
		,('sp_getVolumeFreeSpace', 'GRANT', 'public', 'dbo', 'R')
		,('sp_grant_publication_access', 'GRANT', 'public', 'dbo', 'R')
		,('sp_grantdbaccess', 'GRANT', 'public', 'dbo', 'R')
		,('sp_grantlogin', 'GRANT', 'public', 'dbo', 'R')
		,('sp_help', 'GRANT', 'public', 'dbo', 'R')
		,('sp_help_agent_default', 'GRANT', 'public', 'dbo', 'R')
		,('sp_help_agent_parameter', 'GRANT', 'public', 'dbo', 'R')
		,('sp_help_agent_profile', 'GRANT', 'public', 'dbo', 'R')
		,('sp_help_datatype_mapping', 'GRANT', 'public', 'dbo', 'R')
		,('sp_help_fulltext_catalog_components', 'GRANT', 'public', 'dbo', 'R')
		,('sp_help_fulltext_catalogs', 'GRANT', 'public', 'dbo', 'R')
		,('sp_help_fulltext_catalogs_cursor', 'GRANT', 'public', 'dbo', 'R')
		,('sp_help_fulltext_columns', 'GRANT', 'public', 'dbo', 'R')
		,('sp_help_fulltext_columns_cursor', 'GRANT', 'public', 'dbo', 'R')
		,('sp_help_fulltext_system_components', 'GRANT', 'public', 'dbo', 'R')
		,('sp_help_fulltext_tables', 'GRANT', 'public', 'dbo', 'R')
		,('sp_help_fulltext_tables_cursor', 'GRANT', 'public', 'dbo', 'R')
		,('sp_help_log_shipping_alert_job', 'GRANT', 'public', 'dbo', 'R')
		,('sp_help_log_shipping_monitor', 'GRANT', 'public', 'dbo', 'R')
		,('sp_help_log_shipping_monitor_primary', 'GRANT', 'public', 'dbo', 'R')
		,('sp_help_log_shipping_monitor_secondary', 'GRANT', 'public', 'dbo', 'R')
		,('sp_help_log_shipping_primary_database', 'GRANT', 'public', 'dbo', 'R')
		,('sp_help_log_shipping_primary_secondary', 'GRANT', 'public', 'dbo', 'R')
		,('sp_help_log_shipping_secondary_database', 'GRANT', 'public', 'dbo', 'R')
		,('sp_help_log_shipping_secondary_primary', 'GRANT', 'public', 'dbo', 'R')
		,('sp_help_peerconflictdetection', 'GRANT', 'public', 'dbo', 'R')
		,('sp_help_publication_access', 'GRANT', 'public', 'dbo', 'R')
		,('sp_help_spatial_geography_histogram', 'GRANT', 'public', 'dbo', 'R')
		,('sp_help_spatial_geography_index', 'GRANT', 'public', 'dbo', 'R')
		,('sp_help_spatial_geography_index_xml', 'GRANT', 'public', 'dbo', 'R')
		,('sp_help_spatial_geometry_histogram', 'GRANT', 'public', 'dbo', 'R')
		,('sp_help_spatial_geometry_index', 'GRANT', 'public', 'dbo', 'R')
		,('sp_help_spatial_geometry_index_xml', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helpallowmerge_publication', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helparticle', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helparticlecolumns', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helparticledts', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helpconstraint', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helpdatatypemap', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helpdb', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helpdbfixedrole', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helpdevice', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helpdistpublisher', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helpdistributiondb', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helpdistributor', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helpdistributor_properties', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helpdynamicsnapshot_job', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helpextendedproc', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helpfile', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helpfilegroup', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helpindex', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helplanguage', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helplinkedsrvlogin', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helplogins', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helplogreader_agent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helpmergealternatepublisher', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helpmergearticle', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helpmergearticlecolumn', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helpmergearticleconflicts', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helpmergeconflictrows', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helpmergedeleteconflictrows', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helpmergefilter', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helpmergelogfiles', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helpmergelogfileswithdata', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helpmergelogsettings', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helpmergepartition', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helpmergepublication', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helpmergepullsubscription', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helpmergesubscription', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helpntgroup', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helppeerrequests', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helppeerresponses', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helppublication', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helppublication_snapshot', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helppublicationsync', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helppullsubscription', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helpqreader_agent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helpremotelogin', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helpreplfailovermode', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helpreplicationdb', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helpreplicationdboption', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helpreplicationoption', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helprole', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helprolemember', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helprotect', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helpserver', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helpsort', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helpsrvrole', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helpsrvrolemember', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helpstats', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helpsubscriberinfo', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helpsubscription', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helpsubscription_properties', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helpsubscriptionerrors', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helptext', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helptracertokenhistory', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helptracertokens', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helptrigger', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helpuser', 'GRANT', 'public', 'dbo', 'R')
		,('sp_helpxactsetjob', 'GRANT', 'public', 'dbo', 'R')
		,('sp_http_generate_wsdl_complex', 'GRANT', 'public', 'dbo', 'R')
		,('sp_http_generate_wsdl_defaultcomplexorsimple', 'GRANT', 'public', 'dbo', 'R')
		,('sp_http_generate_wsdl_defaultsimpleorcomplex', 'GRANT', 'public', 'dbo', 'R')
		,('sp_http_generate_wsdl_simple', 'GRANT', 'public', 'dbo', 'R')
		,('sp_identitycolumnforreplication', 'GRANT', 'public', 'dbo', 'R')
		,('sp_IH_LR_GetCacheData', 'GRANT', 'public', 'dbo', 'R')
		,('sp_IHadd_sync_command', 'GRANT', 'public', 'dbo', 'R')
		,('sp_IHarticlecolumn', 'GRANT', 'public', 'dbo', 'R')
		,('sp_IHget_loopback_detection', 'GRANT', 'public', 'dbo', 'R')
		,('sp_IHScriptIdxFile', 'GRANT', 'public', 'dbo', 'R')
		,('sp_IHScriptSchFile', 'GRANT', 'public', 'dbo', 'R')
		,('sp_IHValidateRowFilter', 'GRANT', 'public', 'dbo', 'R')
		,('sp_IHXactSetJob', 'GRANT', 'public', 'dbo', 'R')
		,('sp_indexcolumns_managed', 'GRANT', 'public', 'dbo', 'R')
		,('sp_indexes', 'GRANT', 'public', 'dbo', 'R')
		,('sp_indexes_100_rowset', 'GRANT', 'public', 'dbo', 'R')
		,('sp_indexes_100_rowset2', 'GRANT', 'public', 'dbo', 'R')
		,('sp_indexes_90_rowset', 'GRANT', 'public', 'dbo', 'R')
		,('sp_indexes_90_rowset_rmt', 'GRANT', 'public', 'dbo', 'R')
		,('sp_indexes_90_rowset2', 'GRANT', 'public', 'dbo', 'R')
		,('sp_indexes_managed', 'GRANT', 'public', 'dbo', 'R')
		,('sp_indexes_rowset', 'GRANT', 'public', 'dbo', 'R')
		,('sp_indexes_rowset_rmt', 'GRANT', 'public', 'dbo', 'R')
		,('sp_indexes_rowset2', 'GRANT', 'public', 'dbo', 'R')
		,('sp_indexoption', 'GRANT', 'public', 'dbo', 'R')
		,('sp_invalidate_textptr', 'GRANT', 'public', 'dbo', 'R')
		,('sp_is_makegeneration_needed', 'GRANT', 'public', 'dbo', 'R')
		,('sp_ivindexhasnullcols', 'GRANT', 'public', 'dbo', 'R')
		,('sp_kill_filestream_non_transacted_handles', 'GRANT', 'public', 'dbo', 'R')
		,('sp_kill_oldest_transaction_on_secondary', 'GRANT', 'public', 'dbo', 'R')
		,('sp_lightweightmergemetadataretentioncleanup', 'GRANT', 'public', 'dbo', 'R')
		,('sp_link_publication', 'GRANT', 'public', 'dbo', 'R')
		,('sp_linkedservers', 'GRANT', 'public', 'dbo', 'R')
		,('sp_linkedservers_rowset', 'GRANT', 'public', 'dbo', 'R')
		,('sp_linkedservers_rowset2', 'GRANT', 'public', 'dbo', 'R')
		,('sp_lock', 'GRANT', 'public', 'dbo', 'R')
		,('sp_logshippinginstallmetadata', 'GRANT', 'public', 'dbo', 'R')
		,('sp_lookupcustomresolver', 'GRANT', 'public', 'dbo', 'R')
		,('sp_mapdown_bitmap', 'GRANT', 'public', 'dbo', 'R')
		,('sp_markpendingschemachange', 'GRANT', 'public', 'dbo', 'R')
		,('sp_marksubscriptionvalidation', 'GRANT', 'public', 'dbo', 'R')
		,('sp_memory_optimized_cs_migration', 'GRANT', 'public', 'dbo', 'R')
		,('sp_mergearticlecolumn', 'GRANT', 'public', 'dbo', 'R')
		,('sp_mergecleanupmetadata', 'GRANT', 'public', 'dbo', 'R')
		,('sp_mergedummyupdate', 'GRANT', 'public', 'dbo', 'R')
		,('sp_mergemetadataretentioncleanup', 'GRANT', 'public', 'dbo', 'R')
		,('sp_mergesubscription_cleanup', 'GRANT', 'public', 'dbo', 'R')
		,('sp_mergesubscriptionsummary', 'GRANT', 'public', 'dbo', 'R')
		,('sp_migrate_user_to_contained', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MS_replication_installed', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSacquireHeadofQueueLock', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSacquireserverresourcefordynamicsnapshot', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSacquireSlotLock', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSacquiresnapshotdeliverysessionlock', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSactivate_auto_sub', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSactivatelogbasedarticleobject', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSactivateprocedureexecutionarticleobject', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSadd_anonymous_agent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSadd_article', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSadd_compensating_cmd', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSadd_distribution_agent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSadd_distribution_history', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSadd_dynamic_snapshot_location', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSadd_filteringcolumn', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSadd_log_shipping_error_detail', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSadd_log_shipping_history_detail', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSadd_logreader_agent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSadd_logreader_history', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSadd_merge_agent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSadd_merge_anonymous_agent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSadd_merge_history', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSadd_merge_history90', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSadd_merge_subscription', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSadd_mergereplcommand', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSadd_mergesubentry_indistdb', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSadd_publication', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSadd_qreader_agent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSadd_qreader_history', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSadd_repl_alert', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSadd_repl_command', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSadd_repl_commands27hp', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSadd_repl_error', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSadd_replcmds_mcit', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSadd_replmergealert', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSadd_snapshot_agent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSadd_snapshot_history', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSadd_subscriber_info', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSadd_subscriber_schedule', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSadd_subscription', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSadd_subscription_3rd', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSadd_tracer_history', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSadd_tracer_token', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSaddanonymousreplica', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSadddynamicsnapshotjobatdistributor', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSaddguidcolumn', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSaddguidindex', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSaddinitialarticle', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSaddinitialpublication', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSaddinitialschemaarticle', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSaddinitialsubscription', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSaddlightweightmergearticle', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSaddmergedynamicsnapshotjob', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSaddmergetriggers', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSaddmergetriggers_from_template', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSaddmergetriggers_internal', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSaddpeerlsn', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSaddsubscriptionarticles', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSadjust_pub_identity', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSagent_retry_stethoscope', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSagent_stethoscope', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSallocate_new_identity_range', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSalreadyhavegeneration', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSanonymous_status', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSarticlecleanup', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSbrowsesnapshotfolder', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MScache_agent_parameter', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MScdc_capture_job', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MScdc_cleanup_job', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MScdc_db_ddl_event', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MScdc_ddl_event', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MScdc_logddl', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSchange_article', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSchange_distribution_agent_properties', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSchange_logreader_agent_properties', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSchange_merge_agent_properties', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSchange_mergearticle', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSchange_mergepublication', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSchange_originatorid', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSchange_priority', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSchange_publication', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSchange_retention', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSchange_retention_period_unit', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSchange_snapshot_agent_properties', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSchange_subscription_dts_info', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSchangearticleresolver', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSchangedynamicsnapshotjobatdistributor', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSchangedynsnaplocationatdistributor', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSchangeobjectowner', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MScheck_agent_instance', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MScheck_dropobject', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MScheck_Jet_Subscriber', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MScheck_logicalrecord_metadatamatch', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MScheck_merge_subscription_count', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MScheck_pub_identity', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MScheck_pull_access', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MScheck_snapshot_agent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MScheck_subscription', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MScheck_subscription_expiry', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MScheck_subscription_partition', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MScheck_tran_retention', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MScheckexistsgeneration', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MScheckexistsrecguid', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MScheckfailedprevioussync', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MScheckidentityrange', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MScheckIsPubOfSub', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSchecksharedagentforpublication', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSchecksnapshotstatus', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MScleanup_agent_entry', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MScleanup_conflict', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MScleanup_publication_ADinfo', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MScleanup_subscription_distside_entry', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MScleanupdynamicsnapshotfolder', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MScleanupdynsnapshotvws', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSCleanupForPullReinit', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MScleanupmergepublisher_internal', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSclear_dynamic_snapshot_location', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSclearresetpartialsnapshotprogressbit', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MScomputelastsentgen', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MScomputemergearticlescreationorder', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MScomputemergeunresolvedrefs', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSconflicttableexists', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MScreate_all_article_repl_views', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MScreate_article_repl_views', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MScreate_dist_tables', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MScreate_logical_record_views', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MScreate_sub_tables', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MScreate_tempgenhistorytable', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MScreatedisabledmltrigger', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MScreatedummygeneration', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MScreateglobalreplica', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MScreatelightweightinsertproc', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MScreatelightweightmultipurposeproc', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MScreatelightweightprocstriggersconstraints', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MScreatelightweightupdateproc', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MScreatemergedynamicsnapshot', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MScreateretry', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdbuseraccess', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdbuserpriv', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdefer_check', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdelete_tracer_history', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdeletefoldercontents', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdeletemetadataactionrequest', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdeletepeerconflictrow', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdeleteretry', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdeletetranconflictrow', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdelgenzero', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdelrow', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdelrowsbatch', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdelrowsbatch_downloadonly', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdelsubrows', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdelsubrowsbatch', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdependencies', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdetect_nonlogged_shutdown', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdetectinvalidpeerconfiguration', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdetectinvalidpeersubscription', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdist_activate_auto_sub', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdist_adjust_identity', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdistpublisher_cleanup', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdistribution_counters', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdistributoravailable', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdodatabasesnapshotinitiation', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdopartialdatabasesnapshotinitiation', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdrop_6x_publication', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdrop_6x_replication_agent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdrop_anonymous_entry', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdrop_article', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdrop_distribution_agent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdrop_distribution_agentid_dbowner_proxy', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdrop_dynamic_snapshot_agent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdrop_logreader_agent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdrop_merge_agent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdrop_merge_subscription', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdrop_publication', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdrop_qreader_history', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdrop_snapshot_agent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdrop_snapshot_dirs', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdrop_subscriber_info', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdrop_subscription', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdrop_subscription_3rd', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdrop_tempgenhistorytable', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdroparticleconstraints', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdroparticletombstones', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdropconstraints', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdropdynsnapshotvws', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdropfkreferencingarticle', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdropmergearticle', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdropmergedynamicsnapshotjob', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdropobsoletearticle', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdropretry', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdroptemptable', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdummyupdate', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdummyupdate_logicalrecord', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdummyupdate90', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdummyupdatelightweight', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSdynamicsnapshotjobexistsatdistributor', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenable_publication_for_het_sub', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSensure_single_instance', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenum_distribution', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenum_distribution_s', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenum_distribution_sd', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenum_logicalrecord_changes', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenum_logreader', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenum_logreader_s', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenum_logreader_sd', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenum_merge', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenum_merge_agent_properties', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenum_merge_s', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenum_merge_sd', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenum_merge_subscriptions', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenum_merge_subscriptions_90_publication', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenum_merge_subscriptions_90_publisher', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenum_metadataaction_requests', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenum_qreader', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenum_qreader_s', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenum_qreader_sd', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenum_replication_agents', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenum_replication_job', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenum_replqueues', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenum_replsqlqueues', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenum_snapshot', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenum_snapshot_s', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenum_snapshot_sd', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenum_subscriptions', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenumallpublications', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenumallsubscriptions', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenumarticleslightweight', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenumchanges', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenumchanges_belongtopartition', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenumchanges_notbelongtopartition', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenumchangesdirect', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenumchangeslightweight', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenumcolumns', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenumcolumnslightweight', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenumdeletes_forpartition', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenumdeleteslightweight', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenumdeletesmetadata', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenumdistributionagentproperties', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenumerate_PAL', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenumgenerations', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenumgenerations90', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenumpartialchanges', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenumpartialchangesdirect', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenumpartialdeletes', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenumpubreferences', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenumreplicas', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenumreplicas90', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenumretries', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenumschemachange', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenumsubscriptions', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSenumthirdpartypublicationvendornames', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSestimatemergesnapshotworkload', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSestimatesnapshotworkload', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSevalsubscriberinfo', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSevaluate_change_membership_for_all_articles_in_pubid', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSevaluate_change_membership_for_pubid', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSevaluate_change_membership_for_row', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSexecwithlsnoutput', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSfast_delete_trans', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSfetchAdjustidentityrange', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSfetchidentityrange', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSfillupmissingcols', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSfilterclause', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSfix_6x_tasks', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSfixlineageversions', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSFixSubColumnBitmaps', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSfixupbeforeimagetables', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSflush_access_cache', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSforce_drop_distribution_jobs', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSforcereenumeration', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSforeach_worker', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSforeachdb', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSforeachtable', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSgenerateexpandproc', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSget_agent_names', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSget_attach_state', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSget_DDL_after_regular_snapshot', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSget_dynamic_snapshot_location', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSget_identity_range_info', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSget_jobstate', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSget_last_transaction', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSget_latest_peerlsn', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSget_load_hint', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSget_log_shipping_new_sessionid', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSget_logicalrecord_lineage', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSget_max_used_identity', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSget_min_seqno', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSget_MSmerge_rowtrack_colinfo', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSget_new_xact_seqno', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSget_oledbinfo', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSget_partitionid_eval_proc', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSget_publication_from_taskname', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSget_publisher_rpc', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSget_repl_cmds_anonymous', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSget_repl_commands', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSget_repl_error', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSget_session_statistics', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSget_shared_agent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSget_snapshot_history', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSget_subscriber_partition_id', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSget_subscription_dts_info', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSget_subscription_guid', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSget_synctran_commands', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSget_type_wrapper', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSgetagentoffloadinfo', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSgetalternaterecgens', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSgetarticlereinitvalue', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSgetchangecount', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSgetconflictinsertproc', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSgetconflicttablename', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSGetCurrentPrincipal', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSgetdatametadatabatch', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSgetdbversion', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSgetdynamicsnapshotapplock', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSgetdynsnapvalidationtoken', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSgetgenstatus4rows', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSgetisvalidwindowsloginfromdistributor', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSgetlastrecgen', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSgetlastsentgen', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSgetlastsentrecgens', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSgetlastupdatedtime', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSgetlightweightmetadatabatch', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSgetmakegenerationapplock', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSgetmakegenerationapplock_90', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSgetmaxbcpgen', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSgetmaxsnapshottimestamp', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSgetmergeadminapplock', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSgetmetadata_changedlogicalrecordmembers', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSgetmetadatabatch', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSgetmetadatabatch90', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSgetmetadatabatch90new', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSgetonerow', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSgetonerowlightweight', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSgetpeerconflictrow', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSgetpeerlsns', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSgetpeertopeercommands', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSgetpeerwinnerrow', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSgetpubinfo', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSgetreplicainfo', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSgetreplicastate', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSgetrowmetadata', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSgetrowmetadatalightweight', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSGetServerProperties', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSgetsetupbelong_cost', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSgetsubscriberinfo', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSgetsupportabilitysettings', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSgettrancftsrcrow', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSgettranconflictrow', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSgetversion', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSgrantconnectreplication', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MShaschangeslightweight', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MShasdbaccess', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MShelp_article', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MShelp_distdb', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MShelp_distribution_agentid', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MShelp_identity_property', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MShelp_logreader_agentid', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MShelp_merge_agentid', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MShelp_profile', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MShelp_profilecache', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MShelp_publication', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MShelp_repl_agent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MShelp_replication_status', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MShelp_replication_table', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MShelp_snapshot_agent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MShelp_snapshot_agentid', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MShelp_subscriber_info', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MShelp_subscription', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MShelp_subscription_status', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MShelpcolumns', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MShelpconflictpublications', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MShelpcreatebeforetable', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MShelpdestowner', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MShelpdynamicsnapshotjobatdistributor', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MShelpfulltextindex', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MShelpfulltextscript', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MShelpindex', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MShelplogreader_agent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MShelpmergearticles', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MShelpmergeconflictcounts', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MShelpmergedynamicsnapshotjob', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MShelpmergeidentity', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MShelpmergeschemaarticles', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MShelpobjectpublications', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MShelpreplicationtriggers', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MShelpsnapshot_agent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MShelpsummarypublication', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MShelptracertokenhistory', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MShelptracertokens', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MShelptranconflictcounts', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MShelptype', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MShelpvalidationdate', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSIfExistsSubscription', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSindexspace', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSinit_publication_access', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSinit_subscription_agent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSinitdynamicsubscriber', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSinsert_identity', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSinsertdeleteconflict', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSinserterrorlineage', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSinsertgenerationschemachanges', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSinsertgenhistory', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSinsertlightweightschemachange', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSinsertschemachange', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSinvalidate_snapshot', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSisnonpkukupdateinconflict', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSispeertopeeragent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSispkupdateinconflict', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSispublicationqueued', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSisreplmergeagent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSissnapshotitemapplied', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSkilldb', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSlock_auto_sub', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSlock_distribution_agent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSlocktable', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSloginmappings', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSmakearticleprocs', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSmakebatchinsertproc', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSmakebatchupdateproc', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSmakeconflictinsertproc', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSmakectsview', 'GRANT', 'public', 'dbo', 'R')
		INSERT INTO #va2033_excludes (object_name, state_desc, prin_name, user_name, prin_type)
		VALUES ('sp_MSmakedeleteproc', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSmakedynsnapshotvws', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSmakeexpandproc', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSmakegeneration', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSmakeinsertproc', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSmakemetadataselectproc', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSmakeselectproc', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSmakesystableviews', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSmakeupdateproc', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSmap_partitionid_to_generations', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSmarkreinit', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSmatchkey', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSmerge_alterschemaonly', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSmerge_altertrigger', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSmerge_alterview', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSmerge_ddldispatcher', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSmerge_getgencount', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSmerge_getgencur_public', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSmerge_is_snapshot_required', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSmerge_log_identity_range_allocations', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSmerge_parsegenlist', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSmerge_upgrade_subscriber', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSmergesubscribedb', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSmergeupdatelastsyncinfo', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSneedmergemetadataretentioncleanup', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSNonSQLDDL', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSNonSQLDDLForSchemaDDL', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSobjectprivs', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSpeerapplyresponse', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSpeerapplytopologyinfo', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSpeerconflictdetection_statuscollection_applyresponse', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSpeerconflictdetection_statuscollection_sendresponse', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSpeerconflictdetection_topology_applyresponse', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSpeerdbinfo', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSpeersendresponse', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSpeersendtopologyinfo', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSpeertopeerfwdingexec', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSpost_auto_proc', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSpostapplyscript_forsubscriberprocs', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSprep_exclusive', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSprepare_mergearticle', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSprofile_in_use', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSproxiedmetadata', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSproxiedmetadatabatch', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSproxiedmetadatalightweight', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSpub_adjust_identity', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSpublication_access', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSpublicationcleanup', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSpublicationview', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSquery_syncstates', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSquerysubtype', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSrecordsnapshotdeliveryprogress', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSreenable_check', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSrefresh_anonymous', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSrefresh_publisher_idrange', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSregenerate_mergetriggersprocs', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSregisterdynsnapseqno', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSregistermergesnappubid', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSregistersubscription', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSreinit_failed_subscriptions', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSreinit_hub', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSreinit_subscription', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSreinitoverlappingmergepublications', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSreleasedynamicsnapshotapplock', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSreleasemakegenerationapplock', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSreleasemergeadminapplock', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSreleaseSlotLock', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSreleasesnapshotdeliverysessionlock', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSremove_mergereplcommand', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSremoveoffloadparameter', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSrepl_agentstatussummary', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSrepl_backup_complete', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSrepl_backup_start', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSrepl_check_publisher', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSrepl_createdatatypemappings', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSrepl_distributionagentstatussummary', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSrepl_dropdatatypemappings', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSrepl_enumarticlecolumninfo', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSrepl_enumpublications', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSrepl_enumpublishertables', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSrepl_enumsubscriptions', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSrepl_enumtablecolumninfo', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSrepl_FixPALRole', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSrepl_getdistributorinfo', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSrepl_getpkfkrelation', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSrepl_gettype_mappings', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSrepl_helparticlermo', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSrepl_init_backup_lsns', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSrepl_isdbowner', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSrepl_IsLastPubInSharedSubscription', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSrepl_IsUserInAnyPAL', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSrepl_linkedservers_rowset', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSrepl_mergeagentstatussummary', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSrepl_PAL_rolecheck', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSrepl_raiserror', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSrepl_schema', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSrepl_setNFR', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSrepl_snapshot_helparticlecolumns', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSrepl_snapshot_helppublication', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSrepl_startup_internal', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSrepl_subscription_rowset', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSrepl_testadminconnection', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSrepl_testconnection', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSreplagentjobexists', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSreplcheck_permission', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSreplcheck_pull', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSreplcheck_subscribe', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSreplcheck_subscribe_withddladmin', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSreplcheckoffloadserver', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSreplcopyscriptfile', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSreplraiserror', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSreplremoveuncdir', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSreplupdateschema', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSrequestreenumeration', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSrequestreenumeration_lightweight', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSreset_attach_state', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSreset_queued_reinit', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSreset_subscription', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSreset_subscription_seqno', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSreset_synctran_bit', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSreset_transaction', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSresetsnapshotdeliveryprogress', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSrestoresavedforeignkeys', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSretrieve_publication_attributes', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSscript_article_view', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSscript_dri', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSscript_pub_upd_trig', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSscript_sync_del_proc', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSscript_sync_del_trig', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSscript_sync_ins_proc', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSscript_sync_ins_trig', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSscript_sync_upd_proc', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSscript_sync_upd_trig', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSscriptcustomdelproc', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSscriptcustominsproc', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSscriptcustomupdproc', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSscriptdatabase', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSscriptdb_worker', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSscriptforeignkeyrestore', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSscriptsubscriberprocs', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSscriptviewproc', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSsendtosqlqueue', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSset_dynamic_filter_options', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSset_logicalrecord_metadata', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSset_new_identity_range', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSset_oledb_prop', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSset_snapshot_xact_seqno', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSset_sub_guid', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSset_subscription_properties', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSsetaccesslist', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSsetartprocs', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSsetbit', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSsetconflictscript', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSsetconflicttable', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSsetcontext_bypasswholeddleventbit', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSsetcontext_replagent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSsetgentozero', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSsetlastrecgen', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSsetlastsentgen', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSsetreplicainfo', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSsetreplicaschemaversion', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSsetreplicastatus', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSsetrowmetadata', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSsetsubscriberinfo', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSsetup_identity_range', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSsetup_partition_groups', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSsetup_use_partition_groups', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSsetupbelongs', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSsetupnosyncsubwithlsnatdist', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSsetupnosyncsubwithlsnatdist_cleanup', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSsetupnosyncsubwithlsnatdist_helper', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSSharedFixedDisk', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSSQLDMO70_version', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSSQLDMO80_version', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSSQLDMO90_version', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSSQLOLE_version', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSSQLOLE65_version', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSstartdistribution_agent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSstartmerge_agent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSstartsnapshot_agent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSstopdistribution_agent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSstopmerge_agent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSstopsnapshot_agent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSsub_check_identity', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSsub_set_identity', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSsubscription_status', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSsubscriptionvalidated', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MStablechecks', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MStablekeys', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MStablerefs', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MStablespace', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MStestbit', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MStran_ddlrepl', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MStran_is_snapshot_required', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MStrypurgingoldsnapshotdeliveryprogress', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSuniquename', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSunmarkifneeded', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSunmarkreplinfo', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSunmarkschemaobject', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSunregistersubscription', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSupdate_agenttype_default', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSupdate_singlelogicalrecordmetadata', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSupdate_subscriber_info', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSupdate_subscriber_schedule', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSupdate_subscriber_tracer_history', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSupdate_subscription', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSupdate_tracer_history', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSupdatecachedpeerlsn', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSupdategenerations_afterbcp', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSupdategenhistory', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSupdateinitiallightweightsubscription', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSupdatelastsyncinfo', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSupdatepeerlsn', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSupdaterecgen', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSupdatereplicastate', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSupdatesysmergearticles', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSuplineageversion', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSuploadsupportabilitydata', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSuselightweightreplication', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSvalidate_dest_recgen', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSvalidate_subscription', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSvalidate_wellpartitioned_articles', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSvalidatearticle', 'GRANT', 'public', 'dbo', 'R')
		,('sp_MSwritemergeperfcounter', 'GRANT', 'public', 'dbo', 'R')
		,('sp_new_parallel_nested_tran_id', 'GRANT', 'public', 'dbo', 'R')
		,('sp_objectfilegroup', 'GRANT', 'public', 'dbo', 'R')
		,('sp_oledb_database', 'GRANT', 'public', 'dbo', 'R')
		,('sp_oledb_defdb', 'GRANT', 'public', 'dbo', 'R')
		,('sp_oledb_deflang', 'GRANT', 'public', 'dbo', 'R')
		,('sp_oledb_language', 'GRANT', 'public', 'dbo', 'R')
		,('sp_oledb_ro_usrname', 'GRANT', 'public', 'dbo', 'R')
		,('sp_oledbinfo', 'GRANT', 'public', 'dbo', 'R')
		,('sp_ORbitmap', 'GRANT', 'public', 'dbo', 'R')
		,('sp_password', 'GRANT', 'public', 'dbo', 'R')
		,('sp_peerconflictdetection_tableaug', 'GRANT', 'public', 'dbo', 'R')
		,('sp_pkeys', 'GRANT', 'public', 'dbo', 'R')
		,('sp_polybase_join_group', 'GRANT', 'public', 'dbo', 'R')
		,('sp_polybase_leave_group', 'GRANT', 'public', 'dbo', 'R')
		,('sp_posttracertoken', 'GRANT', 'public', 'dbo', 'R')
		,('sp_prepare', 'GRANT', 'public', 'dbo', 'R')
		,('sp_prepexec', 'GRANT', 'public', 'dbo', 'R')
		,('sp_prepexecrpc', 'GRANT', 'public', 'dbo', 'R')
		,('sp_primary_keys_rowset', 'GRANT', 'public', 'dbo', 'R')
		,('sp_primary_keys_rowset_rmt', 'GRANT', 'public', 'dbo', 'R')
		,('sp_primary_keys_rowset2', 'GRANT', 'public', 'dbo', 'R')
		,('sp_primarykeys', 'GRANT', 'public', 'dbo', 'R')
		,('sp_procedure_params_100_managed', 'GRANT', 'public', 'dbo', 'R')
		,('sp_procedure_params_100_rowset', 'GRANT', 'public', 'dbo', 'R')
		,('sp_procedure_params_100_rowset2', 'GRANT', 'public', 'dbo', 'R')
		,('sp_procedure_params_90_rowset', 'GRANT', 'public', 'dbo', 'R')
		,('sp_procedure_params_90_rowset2', 'GRANT', 'public', 'dbo', 'R')
		,('sp_procedure_params_managed', 'GRANT', 'public', 'dbo', 'R')
		,('sp_procedure_params_rowset', 'GRANT', 'public', 'dbo', 'R')
		,('sp_procedure_params_rowset2', 'GRANT', 'public', 'dbo', 'R')
		,('sp_procedures_rowset', 'GRANT', 'public', 'dbo', 'R')
		,('sp_procedures_rowset2', 'GRANT', 'public', 'dbo', 'R')
		,('sp_processlogshippingmonitorhistory', 'GRANT', 'public', 'dbo', 'R')
		,('sp_processlogshippingmonitorprimary', 'GRANT', 'public', 'dbo', 'R')
		,('sp_processlogshippingmonitorsecondary', 'GRANT', 'public', 'dbo', 'R')
		,('sp_processlogshippingretentioncleanup', 'GRANT', 'public', 'dbo', 'R')
		,('sp_procoption', 'GRANT', 'public', 'dbo', 'R')
		,('sp_prop_oledb_provider', 'GRANT', 'public', 'dbo', 'R')
		,('sp_provider_types_100_rowset', 'GRANT', 'public', 'dbo', 'R')
		,('sp_provider_types_90_rowset', 'GRANT', 'public', 'dbo', 'R')
		,('sp_provider_types_rowset', 'GRANT', 'public', 'dbo', 'R')
		,('sp_publication_validation', 'GRANT', 'public', 'dbo', 'R')
		,('sp_publicationsummary', 'GRANT', 'public', 'dbo', 'R')
		,('sp_publishdb', 'GRANT', 'public', 'dbo', 'R')
		,('sp_publisherproperty', 'GRANT', 'public', 'dbo', 'R')
		,('sp_query_store_flush_db', 'GRANT', 'public', 'dbo', 'R')
		,('sp_query_store_force_plan', 'GRANT', 'public', 'dbo', 'R')
		,('sp_query_store_remove_plan', 'GRANT', 'public', 'dbo', 'R')
		,('sp_query_store_remove_query', 'GRANT', 'public', 'dbo', 'R')
		,('sp_query_store_reset_exec_stats', 'GRANT', 'public', 'dbo', 'R')
		,('sp_query_store_unforce_plan', 'GRANT', 'public', 'dbo', 'R')
		,('sp_rda_deauthorize_db', 'GRANT', 'public', 'dbo', 'R')
		,('sp_rda_get_rpo_duration', 'GRANT', 'public', 'dbo', 'R')
		,('sp_rda_reauthorize_db', 'GRANT', 'public', 'dbo', 'R')
		,('sp_rda_reconcile_batch', 'GRANT', 'public', 'dbo', 'R')
		,('sp_rda_reconcile_columns', 'GRANT', 'public', 'dbo', 'R')
		,('sp_rda_reconcile_indexes', 'GRANT', 'public', 'dbo', 'R')
		,('sp_rda_set_query_mode', 'GRANT', 'public', 'dbo', 'R')
		,('sp_rda_set_rpo_duration', 'GRANT', 'public', 'dbo', 'R')
		,('sp_rda_test_connection', 'GRANT', 'public', 'dbo', 'R')
		,('sp_readerrorlog', 'GRANT', 'public', 'dbo', 'R')
		,('sp_recompile', 'GRANT', 'public', 'dbo', 'R')
		,('sp_redirect_publisher', 'GRANT', 'public', 'dbo', 'R')
		,('sp_refresh_heterogeneous_publisher', 'GRANT', 'public', 'dbo', 'R')
		,('sp_refresh_log_shipping_monitor', 'GRANT', 'public', 'dbo', 'R')
		,('sp_refresh_parameter_encryption', 'GRANT', 'public', 'dbo', 'R')
		,('sp_refreshsqlmodule', 'GRANT', 'public', 'dbo', 'R')
		,('sp_refreshsubscriptions', 'GRANT', 'public', 'dbo', 'R')
		,('sp_refreshview', 'GRANT', 'public', 'dbo', 'R')
		,('sp_register_custom_scripting', 'GRANT', 'public', 'dbo', 'R')
		,('sp_registercustomresolver', 'GRANT', 'public', 'dbo', 'R')
		,('sp_reinitmergepullsubscription', 'GRANT', 'public', 'dbo', 'R')
		,('sp_reinitmergesubscription', 'GRANT', 'public', 'dbo', 'R')
		,('sp_reinitpullsubscription', 'GRANT', 'public', 'dbo', 'R')
		,('sp_reinitsubscription', 'GRANT', 'public', 'dbo', 'R')
		,('sp_releaseapplock', 'GRANT', 'public', 'dbo', 'R')
		,('sp_releaseschemalock', 'GRANT', 'public', 'dbo', 'R')
		,('sp_remote_data_archive_event', 'GRANT', 'public', 'dbo', 'R')
		,('sp_remoteoption', 'GRANT', 'public', 'dbo', 'R')
		,('sp_removedbreplication', 'GRANT', 'public', 'dbo', 'R')
		,('sp_removedistpublisherdbreplication', 'GRANT', 'public', 'dbo', 'R')
		,('sp_removesrvreplication', 'GRANT', 'public', 'dbo', 'R')
		,('sp_rename', 'GRANT', 'public', 'dbo', 'R')
		,('sp_renamedb', 'GRANT', 'public', 'dbo', 'R')
		,('sp_repl_generate_subscriber_event', 'GRANT', 'public', 'dbo', 'R')
		,('sp_repl_generateevent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_repladdcolumn', 'GRANT', 'public', 'dbo', 'R')
		,('sp_replcleanupccsprocs', 'GRANT', 'public', 'dbo', 'R')
		,('sp_replcmds', 'GRANT', 'public', 'dbo', 'R')
		,('sp_replcounters', 'GRANT', 'public', 'dbo', 'R')
		,('sp_replddlparser', 'GRANT', 'public', 'dbo', 'R')
		,('sp_repldeletequeuedtran', 'GRANT', 'public', 'dbo', 'R')
		,('sp_repldone', 'GRANT', 'public', 'dbo', 'R')
		,('sp_repldropcolumn', 'GRANT', 'public', 'dbo', 'R')
		,('sp_replflush', 'GRANT', 'public', 'dbo', 'R')
		,('sp_replgetparsedddlcmd', 'GRANT', 'public', 'dbo', 'R')
		,('sp_replhelp', 'GRANT', 'public', 'dbo', 'R')
		,('sp_replica', 'GRANT', 'public', 'dbo', 'R')
		,('sp_replication_agent_checkup', 'GRANT', 'public', 'dbo', 'R')
		,('sp_replicationdboption', 'GRANT', 'public', 'dbo', 'R')
		,('sp_replincrementlsn', 'GRANT', 'public', 'dbo', 'R')
		,('sp_replmonitorchangepublicationthreshold', 'GRANT', 'public', 'dbo', 'R')
		,('sp_replmonitorhelpmergesession', 'GRANT', 'public', 'dbo', 'R')
		,('sp_replmonitorhelpmergesessiondetail', 'GRANT', 'public', 'dbo', 'R')
		,('sp_replmonitorhelpmergesubscriptionmoreinfo', 'GRANT', 'public', 'dbo', 'R')
		,('sp_replmonitorhelppublication', 'GRANT', 'public', 'dbo', 'R')
		,('sp_replmonitorhelppublicationthresholds', 'GRANT', 'public', 'dbo', 'R')
		,('sp_replmonitorhelppublisher', 'GRANT', 'public', 'dbo', 'R')
		,('sp_replmonitorhelpsubscription', 'GRANT', 'public', 'dbo', 'R')
		,('sp_replmonitorrefreshjob', 'GRANT', 'public', 'dbo', 'R')
		,('sp_replmonitorsubscriptionpendingcmds', 'GRANT', 'public', 'dbo', 'R')
		,('sp_replpostsyncstatus', 'GRANT', 'public', 'dbo', 'R')
		,('sp_replqueuemonitor', 'GRANT', 'public', 'dbo', 'R')
		,('sp_replrestart', 'GRANT', 'public', 'dbo', 'R')
		,('sp_replrethrow', 'GRANT', 'public', 'dbo', 'R')
		,('sp_replsendtoqueue', 'GRANT', 'public', 'dbo', 'R')
		,('sp_replsetoriginator', 'GRANT', 'public', 'dbo', 'R')
		,('sp_replsetsyncstatus', 'GRANT', 'public', 'dbo', 'R')
		,('sp_replshowcmds', 'GRANT', 'public', 'dbo', 'R')
		,('sp_replsqlqgetrows', 'GRANT', 'public', 'dbo', 'R')
		,('sp_replsync', 'GRANT', 'public', 'dbo', 'R')
		,('sp_repltrans', 'GRANT', 'public', 'dbo', 'R')
		,('sp_replwritetovarbin', 'GRANT', 'public', 'dbo', 'R')
		,('sp_requestpeerresponse', 'GRANT', 'public', 'dbo', 'R')
		,('sp_requestpeertopologyinfo', 'GRANT', 'public', 'dbo', 'R')
		,('sp_reserve_http_namespace', 'GRANT', 'public', 'dbo', 'R')
		,('sp_reset_connection', 'GRANT', 'public', 'dbo', 'R')
		,('sp_reset_session_context', 'GRANT', 'public', 'dbo', 'R')
		,('sp_resetsnapshotdeliveryprogress', 'GRANT', 'public', 'dbo', 'R')
		,('sp_resign_database', 'GRANT', 'public', 'dbo', 'R')
		,('sp_restoredbreplication', 'GRANT', 'public', 'dbo', 'R')
		,('sp_restoremergeidentityrange', 'GRANT', 'public', 'dbo', 'R')
		,('sp_resyncexecute', 'GRANT', 'public', 'dbo', 'R')
		,('sp_resyncexecutesql', 'GRANT', 'public', 'dbo', 'R')
		,('sp_resyncmergesubscription', 'GRANT', 'public', 'dbo', 'R')
		,('sp_resyncprepare', 'GRANT', 'public', 'dbo', 'R')
		,('sp_resyncuniquetable', 'GRANT', 'public', 'dbo', 'R')
		,('sp_revoke_publication_access', 'GRANT', 'public', 'dbo', 'R')
		,('sp_revokedbaccess', 'GRANT', 'public', 'dbo', 'R')
		,('sp_revokelogin', 'GRANT', 'public', 'dbo', 'R')
		,('sp_rollback_parallel_nested_tran', 'GRANT', 'public', 'dbo', 'R')
		,('sp_schemafilter', 'GRANT', 'public', 'dbo', 'R')
		,('sp_schemata_rowset', 'GRANT', 'public', 'dbo', 'R')
		,('sp_script_reconciliation_delproc', 'GRANT', 'public', 'dbo', 'R')
		,('sp_script_reconciliation_insproc', 'GRANT', 'public', 'dbo', 'R')
		,('sp_script_reconciliation_sinsproc', 'GRANT', 'public', 'dbo', 'R')
		,('sp_script_reconciliation_vdelproc', 'GRANT', 'public', 'dbo', 'R')
		,('sp_script_reconciliation_xdelproc', 'GRANT', 'public', 'dbo', 'R')
		,('sp_script_synctran_commands', 'GRANT', 'public', 'dbo', 'R')
		,('sp_scriptdelproc', 'GRANT', 'public', 'dbo', 'R')
		,('sp_scriptdynamicupdproc', 'GRANT', 'public', 'dbo', 'R')
		,('sp_scriptinsproc', 'GRANT', 'public', 'dbo', 'R')
		,('sp_scriptmappedupdproc', 'GRANT', 'public', 'dbo', 'R')
		,('sp_scriptpublicationcustomprocs', 'GRANT', 'public', 'dbo', 'R')
		,('sp_scriptsinsproc', 'GRANT', 'public', 'dbo', 'R')
		,('sp_scriptsubconflicttable', 'GRANT', 'public', 'dbo', 'R')
		,('sp_scriptsupdproc', 'GRANT', 'public', 'dbo', 'R')
		,('sp_scriptupdproc', 'GRANT', 'public', 'dbo', 'R')
		,('sp_scriptvdelproc', 'GRANT', 'public', 'dbo', 'R')
		,('sp_scriptvupdproc', 'GRANT', 'public', 'dbo', 'R')
		,('sp_scriptxdelproc', 'GRANT', 'public', 'dbo', 'R')
		,('sp_scriptxupdproc', 'GRANT', 'public', 'dbo', 'R')
		,('sp_sequence_get_range', 'GRANT', 'public', 'dbo', 'R')
		,('sp_server_diagnostics', 'GRANT', 'public', 'dbo', 'R')
		,('sp_server_info', 'GRANT', 'public', 'dbo', 'R')
		,('sp_serveroption', 'GRANT', 'public', 'dbo', 'R')
		,('sp_set_session_context', 'GRANT', 'public', 'dbo', 'R')
		,('sp_setapprole', 'GRANT', 'public', 'dbo', 'R')
		,('sp_SetAutoSAPasswordAndDisable', 'GRANT', 'public', 'dbo', 'R')
		,('sp_setdefaultdatatypemapping', 'GRANT', 'public', 'dbo', 'R')
		,('sp_setnetname', 'GRANT', 'public', 'dbo', 'R')
		,('sp_SetOBDCertificate', 'GRANT', 'public', 'dbo', 'R')
		,('sp_setOraclepackageversion', 'GRANT', 'public', 'dbo', 'R')
		,('sp_setreplfailovermode', 'GRANT', 'public', 'dbo', 'R')
		,('sp_setsubscriptionxactseqno', 'GRANT', 'public', 'dbo', 'R')
		,('sp_settriggerorder', 'GRANT', 'public', 'dbo', 'R')
		,('sp_setuserbylogin', 'GRANT', 'public', 'dbo', 'R')
		,('sp_showcolv', 'GRANT', 'public', 'dbo', 'R')
		,('sp_showlineage', 'GRANT', 'public', 'dbo', 'R')
		,('sp_showmemo_xml', 'GRANT', 'public', 'dbo', 'R')
		,('sp_showpendingchanges', 'GRANT', 'public', 'dbo', 'R')
		,('sp_showrowreplicainfo', 'GRANT', 'public', 'dbo', 'R')
		,('sp_sm_detach', 'GRANT', 'public', 'dbo', 'R')
		,('sp_spaceused', 'GRANT', 'public', 'dbo', 'R')
		,('sp_spaceused_remote_data_archive', 'GRANT', 'public', 'dbo', 'R')
		,('sp_sparse_columns_100_rowset', 'GRANT', 'public', 'dbo', 'R')
		,('sp_special_columns', 'GRANT', 'public', 'dbo', 'R')
		,('sp_special_columns_100', 'GRANT', 'public', 'dbo', 'R')
		,('sp_special_columns_90', 'GRANT', 'public', 'dbo', 'R')
		,('sp_sproc_columns', 'GRANT', 'public', 'dbo', 'R')
		,('sp_sproc_columns_100', 'GRANT', 'public', 'dbo', 'R')
		,('sp_sproc_columns_90', 'GRANT', 'public', 'dbo', 'R')
		,('sp_sqlagent_add_job', 'GRANT', 'public', 'dbo', 'R')
		,('sp_sqlagent_add_jobstep', 'GRANT', 'public', 'dbo', 'R')
		,('sp_sqlagent_delete_job', 'GRANT', 'public', 'dbo', 'R')
		,('sp_sqlagent_help_jobstep', 'GRANT', 'public', 'dbo', 'R')
		,('sp_sqlagent_log_job_history', 'GRANT', 'public', 'dbo', 'R')
		,('sp_sqlagent_start_job', 'GRANT', 'public', 'dbo', 'R')
		,('sp_sqlagent_stop_job', 'GRANT', 'public', 'dbo', 'R')
		,('sp_sqlagent_verify_database_context', 'GRANT', 'public', 'dbo', 'R')
		,('sp_sqlagent_write_jobstep_log', 'GRANT', 'public', 'dbo', 'R')
		,('sp_sqlexec', 'GRANT', 'public', 'dbo', 'R')
		,('sp_srvrolepermission', 'GRANT', 'public', 'dbo', 'R')
		,('sp_start_user_instance', 'GRANT', 'public', 'dbo', 'R')
		,('sp_startmergepullsubscription_agent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_startmergepushsubscription_agent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_startpublication_snapshot', 'GRANT', 'public', 'dbo', 'R')
		,('sp_startpullsubscription_agent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_startpushsubscription_agent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_statistics', 'GRANT', 'public', 'dbo', 'R')
		,('sp_statistics_100', 'GRANT', 'public', 'dbo', 'R')
		,('sp_statistics_rowset', 'GRANT', 'public', 'dbo', 'R')
		,('sp_statistics_rowset2', 'GRANT', 'public', 'dbo', 'R')
		,('sp_stopmergepullsubscription_agent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_stopmergepushsubscription_agent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_stoppublication_snapshot', 'GRANT', 'public', 'dbo', 'R')
		,('sp_stoppullsubscription_agent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_stoppushsubscription_agent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_stored_procedures', 'GRANT', 'public', 'dbo', 'R')
		,('sp_subscribe', 'GRANT', 'public', 'dbo', 'R')
		,('sp_subscription_cleanup', 'GRANT', 'public', 'dbo', 'R')
		,('sp_subscriptionsummary', 'GRANT', 'public', 'dbo', 'R')
		,('sp_sysdac_add_history_entry', 'GRANT', 'public', 'dbo', 'R')
		,('sp_sysdac_add_instance', 'GRANT', 'public', 'dbo', 'R')
		,('sp_sysdac_delete_history', 'GRANT', 'public', 'dbo', 'R')
		,('sp_sysdac_delete_instance', 'GRANT', 'public', 'dbo', 'R')
		,('sp_sysdac_drop_database', 'GRANT', 'public', 'dbo', 'R')
		,('sp_sysdac_ensure_dac_creator', 'GRANT', 'public', 'dbo', 'R')
		,('sp_sysdac_rename_database', 'GRANT', 'public', 'dbo', 'R')
		,('sp_sysdac_resolve_pending_entry', 'GRANT', 'public', 'dbo', 'R')
		,('sp_sysdac_rollback_all_pending_objects', 'GRANT', 'public', 'dbo', 'R')
		,('sp_sysdac_rollback_committed_step', 'GRANT', 'public', 'dbo', 'R')
		,('sp_sysdac_rollback_pending_object', 'GRANT', 'public', 'dbo', 'R')
		,('sp_sysdac_setreadonly_database', 'GRANT', 'public', 'dbo', 'R')
		,('sp_sysdac_update_history_entry', 'GRANT', 'public', 'dbo', 'R')
		,('sp_sysdac_upgrade_instance', 'GRANT', 'public', 'dbo', 'R')
		,('sp_syspolicy_subscribe_to_policy_category', 'GRANT', 'public', 'dbo', 'R')
		,('sp_syspolicy_unsubscribe_from_policy_category', 'GRANT', 'public', 'dbo', 'R')
		,('sp_syspolicy_update_ddl_trigger', 'GRANT', 'public', 'dbo', 'R')
		,('sp_syspolicy_update_event_notification', 'GRANT', 'public', 'dbo', 'R')
		,('sp_sysdac_update_instance', 'GRANT', 'public', 'dbo', 'R')
		,('sp_table_constraints_rowset', 'GRANT', 'public', 'dbo', 'R')
		,('sp_table_constraints_rowset2', 'GRANT', 'public', 'dbo', 'R')
		,('sp_table_privileges', 'GRANT', 'public', 'dbo', 'R')
		,('sp_table_privileges_ex', 'GRANT', 'public', 'dbo', 'R')
		,('sp_table_privileges_rowset', 'GRANT', 'public', 'dbo', 'R')
		,('sp_table_privileges_rowset_rmt', 'GRANT', 'public', 'dbo', 'R')
		,('sp_table_privileges_rowset2', 'GRANT', 'public', 'dbo', 'R')
		,('sp_table_statistics_rowset', 'GRANT', 'public', 'dbo', 'R')
		,('sp_table_statistics2_rowset', 'GRANT', 'public', 'dbo', 'R')
		,('sp_table_type_columns_100', 'GRANT', 'public', 'dbo', 'R')
		,('sp_table_type_columns_100_rowset', 'GRANT', 'public', 'dbo', 'R')
		,('sp_table_type_pkeys', 'GRANT', 'public', 'dbo', 'R')
		,('sp_table_type_primary_keys_rowset', 'GRANT', 'public', 'dbo', 'R')
		,('sp_table_types', 'GRANT', 'public', 'dbo', 'R')
		,('sp_table_types_rowset', 'GRANT', 'public', 'dbo', 'R')
		,('sp_table_validation', 'GRANT', 'public', 'dbo', 'R')
		,('sp_tablecollations', 'GRANT', 'public', 'dbo', 'R')
		,('sp_tablecollations_100', 'GRANT', 'public', 'dbo', 'R')
		,('sp_tablecollations_90', 'GRANT', 'public', 'dbo', 'R')
		,('sp_tableoption', 'GRANT', 'public', 'dbo', 'R')
		,('sp_tables', 'GRANT', 'public', 'dbo', 'R')
		,('sp_tables_ex', 'GRANT', 'public', 'dbo', 'R')
		,('sp_tables_info_90_rowset', 'GRANT', 'public', 'dbo', 'R')
		,('sp_tables_info_90_rowset_64', 'GRANT', 'public', 'dbo', 'R')
		,('sp_tables_info_90_rowset2', 'GRANT', 'public', 'dbo', 'R')
		,('sp_tables_info_90_rowset2_64', 'GRANT', 'public', 'dbo', 'R')
		,('sp_tables_info_rowset', 'GRANT', 'public', 'dbo', 'R')
		,('sp_tables_info_rowset_64', 'GRANT', 'public', 'dbo', 'R')
		,('sp_tables_info_rowset2', 'GRANT', 'public', 'dbo', 'R')
		,('sp_tables_info_rowset2_64', 'GRANT', 'public', 'dbo', 'R')
		,('sp_tables_rowset', 'GRANT', 'public', 'dbo', 'R')
		,('sp_tables_rowset_rmt', 'GRANT', 'public', 'dbo', 'R')
		,('sp_tables_rowset2', 'GRANT', 'public', 'dbo', 'R')
		,('sp_tableswc', 'GRANT', 'public', 'dbo', 'R')
		,('sp_testlinkedserver', 'GRANT', 'public', 'dbo', 'R')
		,('sp_trace_create', 'GRANT', 'public', 'dbo', 'R')
		,('sp_trace_generateevent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_trace_getdata', 'GRANT', 'public', 'dbo', 'R')
		,('sp_trace_setevent', 'GRANT', 'public', 'dbo', 'R')
		,('sp_trace_setfilter', 'GRANT', 'public', 'dbo', 'R')
		,('sp_trace_setstatus', 'GRANT', 'public', 'dbo', 'R')
		,('sp_try_set_session_context', 'GRANT', 'public', 'dbo', 'R')
		,('sp_unbindefault', 'GRANT', 'public', 'dbo', 'R')
		,('sp_unbindrule', 'GRANT', 'public', 'dbo', 'R')
		,('sp_unprepare', 'GRANT', 'public', 'dbo', 'R')
		,('sp_unregister_custom_scripting', 'GRANT', 'public', 'dbo', 'R')
		,('sp_unregistercustomresolver', 'GRANT', 'public', 'dbo', 'R')
		,('sp_unsetapprole', 'GRANT', 'public', 'dbo', 'R')
		,('sp_unsubscribe', 'GRANT', 'public', 'dbo', 'R')
		,('sp_update_agent_profile', 'GRANT', 'public', 'dbo', 'R')
		,('sp_update_user_instance', 'GRANT', 'public', 'dbo', 'R')
		,('sp_updateextendedproperty', 'GRANT', 'public', 'dbo', 'R')
		,('sp_updatestats', 'GRANT', 'public', 'dbo', 'R')
		,('sp_upgrade_log_shipping', 'GRANT', 'public', 'dbo', 'R')
		,('sp_user_counter1', 'GRANT', 'public', 'dbo', 'R')
		,('sp_user_counter10', 'GRANT', 'public', 'dbo', 'R')
		,('sp_user_counter2', 'GRANT', 'public', 'dbo', 'R')
		,('sp_user_counter3', 'GRANT', 'public', 'dbo', 'R')
		,('sp_user_counter4', 'GRANT', 'public', 'dbo', 'R')
		,('sp_user_counter5', 'GRANT', 'public', 'dbo', 'R')
		,('sp_user_counter6', 'GRANT', 'public', 'dbo', 'R')
		,('sp_user_counter7', 'GRANT', 'public', 'dbo', 'R')
		,('sp_user_counter8', 'GRANT', 'public', 'dbo', 'R')
		,('sp_user_counter9', 'GRANT', 'public', 'dbo', 'R')
		,('sp_usertypes_rowset', 'GRANT', 'public', 'dbo', 'R')
		,('sp_usertypes_rowset_rmt', 'GRANT', 'public', 'dbo', 'R')
		,('sp_usertypes_rowset2', 'GRANT', 'public', 'dbo', 'R')
		,('sp_validate_redirected_publisher', 'GRANT', 'public', 'dbo', 'R')
		,('sp_validate_replica_hosts_as_publishers', 'GRANT', 'public', 'dbo', 'R')
		,('sp_validatecache', 'GRANT', 'public', 'dbo', 'R')
		,('sp_validatelogins', 'GRANT', 'public', 'dbo', 'R')
		,('sp_validatemergepublication', 'GRANT', 'public', 'dbo', 'R')
		,('sp_validatemergepullsubscription', 'GRANT', 'public', 'dbo', 'R')
		,('sp_validatemergesubscription', 'GRANT', 'public', 'dbo', 'R')
		,('sp_validlang', 'GRANT', 'public', 'dbo', 'R')
		,('sp_validname', 'GRANT', 'public', 'dbo', 'R')
		,('sp_verifypublisher', 'GRANT', 'public', 'dbo', 'R')
		,('sp_views_rowset', 'GRANT', 'public', 'dbo', 'R')
		,('sp_views_rowset2', 'GRANT', 'public', 'dbo', 'R')
		,('sp_vupgrade_mergeobjects', 'GRANT', 'public', 'dbo', 'R')
		,('sp_vupgrade_mergetables', 'GRANT', 'public', 'dbo', 'R')
		,('sp_vupgrade_replication', 'GRANT', 'public', 'dbo', 'R')
		,('sp_vupgrade_replsecurity_metadata', 'GRANT', 'public', 'dbo', 'R')
		,('sp_who', 'GRANT', 'public', 'dbo', 'R')
		,('sp_who2', 'GRANT', 'public', 'dbo', 'R')
		,('sp_xml_preparedocument', 'GRANT', 'public', 'dbo', 'R')
		,('sp_xml_removedocument', 'GRANT', 'public', 'dbo', 'R')
		,('sp_xml_schema_rowset', 'GRANT', 'public', 'dbo', 'R')
		,('sp_xml_schema_rowset2', 'GRANT', 'public', 'dbo', 'R')
		,('sp_xtp_bind_db_resource_pool', 'GRANT', 'public', 'dbo', 'R')
		,('sp_xtp_checkpoint_force_garbage_collection', 'GRANT', 'public', 'dbo', 'R')
		,('sp_xtp_control_proc_exec_stats', 'GRANT', 'public', 'dbo', 'R')
		,('sp_xtp_control_query_exec_stats', 'GRANT', 'public', 'dbo', 'R')
		,('sp_xtp_flush_temporal_history', 'GRANT', 'public', 'dbo', 'R')
		,('sp_xtp_kill_active_transactions', 'GRANT', 'public', 'dbo', 'R')
		,('sp_xtp_merge_checkpoint_files', 'GRANT', 'public', 'dbo', 'R')
		,('sp_xtp_objects_present', 'GRANT', 'public', 'dbo', 'R')
		,('sp_xtp_set_memory_quota', 'GRANT', 'public', 'dbo', 'R')
		,('sp_xtp_slo_can_downgrade', 'GRANT', 'public', 'dbo', 'R')
		,('sp_xtp_slo_downgrade_finished', 'GRANT', 'public', 'dbo', 'R')
		,('sp_xtp_slo_prepare_to_downgrade', 'GRANT', 'public', 'dbo', 'R')
		,('sp_xtp_unbind_db_resource_pool', 'GRANT', 'public', 'dbo', 'R')
		,('xp_dirtree', 'GRANT', 'public', 'dbo', 'R')
		,('xp_fileexist', 'GRANT', 'public', 'dbo', 'R')
		,('xp_fixeddrives', 'GRANT', 'public', 'dbo', 'R')
		,('xp_getnetname', 'GRANT', 'public', 'dbo', 'R')
		,('xp_grantlogin', 'GRANT', 'public', 'dbo', 'R')
		,('xp_instance_regread', 'GRANT', 'public', 'dbo', 'R')
		,('xp_msver', 'GRANT', 'public', 'dbo', 'R')
		,('xp_qv', 'GRANT', 'public', 'dbo', 'R')
		,('xp_regread', 'GRANT', 'public', 'dbo', 'R')
		,('xp_repl_convert_encrypt_sysadmin_wrapper', 'GRANT', 'public', 'dbo', 'R')
		,('xp_replposteor', 'GRANT', 'public', 'dbo', 'R')
		,('xp_revokelogin', 'GRANT', 'public', 'dbo', 'R')
		,('xp_sprintf', 'GRANT', 'public', 'dbo', 'R')
		,('xp_sscanf', 'GRANT', 'public', 'dbo', 'R')
		,('sp_send_dbmail', 'GRANT', 'DatabaseMailUserRole', 'dbo', 'R')
		,('sysmail_delete_mailitems_sp', 'GRANT', 'DatabaseMailUserRole', 'dbo', 'R')
		,('sysmail_help_status_sp', 'GRANT', 'DatabaseMailUserRole', 'dbo', 'R')
		,('sp_ssis_addfolder', 'GRANT', 'db_ssisadmin', 'dbo', 'R')
		,('sp_ssis_addlogentry', 'GRANT', 'db_ssisadmin', 'dbo', 'R')
		,('sp_ssis_checkexists', 'GRANT', 'db_ssisadmin', 'dbo', 'R')
		,('sp_ssis_deletefolder', 'GRANT', 'db_ssisadmin', 'dbo', 'R')
		,('sp_ssis_deletepackage', 'GRANT', 'db_ssisadmin', 'dbo', 'R')
		,('sp_ssis_getfolder', 'GRANT', 'db_ssisadmin', 'dbo', 'R')
		,('sp_ssis_getpackage', 'GRANT', 'db_ssisadmin', 'dbo', 'R')
		,('sp_ssis_getpackageroles', 'GRANT', 'db_ssisadmin', 'dbo', 'R')
		,('sp_ssis_listfolders', 'GRANT', 'db_ssisadmin', 'dbo', 'R')
		,('sp_ssis_listpackages', 'GRANT', 'db_ssisadmin', 'dbo', 'R')
		,('sp_ssis_putpackage', 'GRANT', 'db_ssisadmin', 'dbo', 'R')
		,('sp_ssis_renamefolder', 'GRANT', 'db_ssisadmin', 'dbo', 'R')
		,('sp_ssis_setpackageroles', 'GRANT', 'db_ssisadmin', 'dbo', 'R')
		,('sp_ssis_addfolder', 'GRANT', 'db_ssisltduser', 'dbo', 'R')
		,('sp_ssis_addlogentry', 'GRANT', 'db_ssisltduser', 'dbo', 'R')
		,('sp_ssis_checkexists', 'GRANT', 'db_ssisltduser', 'dbo', 'R')
		,('sp_ssis_deletefolder', 'GRANT', 'db_ssisltduser', 'dbo', 'R')
		,('sp_ssis_deletepackage', 'GRANT', 'db_ssisltduser', 'dbo', 'R')
		,('sp_ssis_getfolder', 'GRANT', 'db_ssisltduser', 'dbo', 'R')
		,('sp_ssis_getpackage', 'GRANT', 'db_ssisltduser', 'dbo', 'R')
		,('sp_ssis_getpackageroles', 'GRANT', 'db_ssisltduser', 'dbo', 'R')
		,('sp_ssis_listfolders', 'GRANT', 'db_ssisltduser', 'dbo', 'R')
		,('sp_ssis_listpackages', 'GRANT', 'db_ssisltduser', 'dbo', 'R')
		,('sp_ssis_putpackage', 'GRANT', 'db_ssisltduser', 'dbo', 'R')
		,('sp_ssis_renamefolder', 'GRANT', 'db_ssisltduser', 'dbo', 'R')
		,('sp_ssis_setpackageroles', 'GRANT', 'db_ssisltduser', 'dbo', 'R')
		,('sp_ssis_checkexists', 'GRANT', 'db_ssisoperator', 'dbo', 'R')
		,('sp_ssis_deletepackage', 'GRANT', 'db_ssisoperator', 'dbo', 'R')
		,('sp_ssis_getfolder', 'GRANT', 'db_ssisoperator', 'dbo', 'R')
		,('sp_ssis_getpackage', 'GRANT', 'db_ssisoperator', 'dbo', 'R')
		,('sp_ssis_listfolders', 'GRANT', 'db_ssisoperator', 'dbo', 'R')
		,('sp_ssis_listpackages', 'GRANT', 'db_ssisoperator', 'dbo', 'R')
		,('sp_ssis_putpackage', 'GRANT', 'db_ssisoperator', 'dbo', 'R')
		,('fn_syscollector_highest_incompatible_mdw_version', 'GRANT', 'dc_admin', 'dbo', 'R')
		,('sp_syscollector_cleanup_collector', 'GRANT', 'dc_admin', 'dbo', 'R')
		,('sp_syscollector_create_collection_item', 'GRANT', 'dc_admin', 'dbo', 'R')
		,('sp_syscollector_create_collection_set', 'GRANT', 'dc_admin', 'dbo', 'R')
		,('sp_syscollector_create_collector_type', 'GRANT', 'dc_admin', 'dbo', 'R')
		,('sp_syscollector_delete_collection_item', 'GRANT', 'dc_admin', 'dbo', 'R')
		,('sp_syscollector_delete_collection_set', 'GRANT', 'dc_admin', 'dbo', 'R')
		,('sp_syscollector_delete_collector_type', 'GRANT', 'dc_admin', 'dbo', 'R')
		,('sp_syscollector_set_cache_directory', 'GRANT', 'dc_admin', 'dbo', 'R')
		,('sp_syscollector_set_cache_window', 'GRANT', 'dc_admin', 'dbo', 'R')
		,('sp_syscollector_set_warehouse_database_name', 'GRANT', 'dc_admin', 'dbo', 'R')
		,('sp_syscollector_set_warehouse_instance_name', 'GRANT', 'dc_admin', 'dbo', 'R')
		,('fn_syscollector_find_collection_set_root', 'GRANT', 'dc_operator', 'dbo', 'R')
		,('sp_syscollector_create_tsql_query_collector', 'GRANT', 'dc_operator', 'dbo', 'R')
		,('sp_syscollector_delete_execution_log_tree', 'GRANT', 'dc_operator', 'dbo', 'R')
		,('sp_syscollector_disable_collector', 'GRANT', 'dc_operator', 'dbo', 'R')
		,('sp_syscollector_enable_collector', 'GRANT', 'dc_operator', 'dbo', 'R')
		,('sp_syscollector_get_tsql_query_collector_package_ids', 'GRANT', 'dc_operator', 'dbo', 'R')
		,('sp_syscollector_run_collection_set', 'GRANT', 'dc_operator', 'dbo', 'R')
		,('sp_syscollector_start_collection_set', 'GRANT', 'dc_operator', 'dbo', 'R')
		,('sp_syscollector_stop_collection_set', 'GRANT', 'dc_operator', 'dbo', 'R')
		,('sp_syscollector_update_collection_item', 'GRANT', 'dc_operator', 'dbo', 'R')
		,('sp_syscollector_update_collection_set', 'GRANT', 'dc_operator', 'dbo', 'R')
		,('sp_syscollector_upload_collection_set', 'GRANT', 'dc_operator', 'dbo', 'R')
		,('sp_verify_subsystems', 'GRANT', 'dc_operator', 'dbo', 'R')
		,('fn_syscollector_highest_incompatible_mdw_version', 'GRANT', 'dc_proxy', 'dbo', 'R')
		,('sp_syscollector_create_tsql_query_collector', 'GRANT', 'dc_proxy', 'dbo', 'R')
		,('sp_syscollector_event_oncollectionbegin', 'GRANT', 'dc_proxy', 'dbo', 'R')
		,('sp_syscollector_event_oncollectionend', 'GRANT', 'dc_proxy', 'dbo', 'R')
		,('sp_syscollector_event_onerror', 'GRANT', 'dc_proxy', 'dbo', 'R')
		,('sp_syscollector_event_onpackagebegin', 'GRANT', 'dc_proxy', 'dbo', 'R')
		,('sp_syscollector_event_onpackageend', 'GRANT', 'dc_proxy', 'dbo', 'R')
		,('sp_syscollector_event_onpackageupdate', 'GRANT', 'dc_proxy', 'dbo', 'R')
		,('sp_syscollector_event_onstatsupdate', 'GRANT', 'dc_proxy', 'dbo', 'R')
		,('sp_syscollector_get_tsql_query_collector_package_ids', 'GRANT', 'dc_proxy', 'dbo', 'R')
		,('sp_syscollector_get_warehouse_connection_string', 'GRANT', 'dc_proxy', 'dbo', 'R')
		,('sp_syscollector_snapshot_dm_exec_query_stats', 'GRANT', 'dc_proxy', 'dbo', 'R')
		,('sp_syscollector_snapshot_dm_exec_requests', 'GRANT', 'dc_proxy', 'dbo', 'R')
		,('sp_syspolicy_add_condition', 'GRANT', 'PolicyAdministratorRole', 'dbo', 'R')
		,('sp_syspolicy_add_object_set', 'GRANT', 'PolicyAdministratorRole', 'dbo', 'R')
		,('sp_syspolicy_add_policy', 'GRANT', 'PolicyAdministratorRole', 'dbo', 'R')
		,('sp_syspolicy_add_policy_category', 'GRANT', 'PolicyAdministratorRole', 'dbo', 'R')
		,('sp_syspolicy_add_policy_category_subscription', 'GRANT', 'PolicyAdministratorRole', 'dbo', 'R')
		,('sp_syspolicy_add_target_set', 'GRANT', 'PolicyAdministratorRole', 'dbo', 'R')
		,('sp_syspolicy_add_target_set_level', 'GRANT', 'PolicyAdministratorRole', 'dbo', 'R')
		,('sp_syspolicy_configure', 'GRANT', 'PolicyAdministratorRole', 'dbo', 'R')
		,('sp_syspolicy_create_purge_job', 'GRANT', 'PolicyAdministratorRole', 'dbo', 'R')
		,('sp_syspolicy_delete_condition', 'GRANT', 'PolicyAdministratorRole', 'dbo', 'R')
		,('sp_syspolicy_delete_object_set', 'GRANT', 'PolicyAdministratorRole', 'dbo', 'R')
		,('sp_syspolicy_delete_policy', 'GRANT', 'PolicyAdministratorRole', 'dbo', 'R')
		,('sp_syspolicy_delete_policy_category', 'GRANT', 'PolicyAdministratorRole', 'dbo', 'R')
		,('sp_syspolicy_delete_policy_category_subscription', 'GRANT', 'PolicyAdministratorRole', 'dbo', 'R')
		,('sp_syspolicy_dispatch_event', 'GRANT', 'PolicyAdministratorRole', 'dbo', 'R')
		,('sp_syspolicy_log_policy_execution_detail', 'GRANT', 'PolicyAdministratorRole', 'dbo', 'R')
		,('sp_syspolicy_log_policy_execution_end', 'GRANT', 'PolicyAdministratorRole', 'dbo', 'R')
		,('sp_syspolicy_log_policy_execution_start', 'GRANT', 'PolicyAdministratorRole', 'dbo', 'R')
		,('sp_syspolicy_purge_health_state', 'GRANT', 'PolicyAdministratorRole', 'dbo', 'R')
		,('sp_syspolicy_purge_history', 'GRANT', 'PolicyAdministratorRole', 'dbo', 'R')
		,('sp_syspolicy_rename_condition', 'GRANT', 'PolicyAdministratorRole', 'dbo', 'R')
		,('sp_syspolicy_rename_policy', 'GRANT', 'PolicyAdministratorRole', 'dbo', 'R')
		,('sp_syspolicy_rename_policy_category', 'GRANT', 'PolicyAdministratorRole', 'dbo', 'R')
		,('sp_syspolicy_repair_policy_automation', 'GRANT', 'PolicyAdministratorRole', 'dbo', 'R')
		,('sp_syspolicy_set_config_enabled', 'GRANT', 'PolicyAdministratorRole', 'dbo', 'R')
		,('sp_syspolicy_set_config_history_retention', 'GRANT', 'PolicyAdministratorRole', 'dbo', 'R')
		,('sp_syspolicy_set_log_on_success', 'GRANT', 'PolicyAdministratorRole', 'dbo', 'R')
		,('sp_syspolicy_update_condition', 'GRANT', 'PolicyAdministratorRole', 'dbo', 'R')
		,('sp_syspolicy_update_policy', 'GRANT', 'PolicyAdministratorRole', 'dbo', 'R')
		,('sp_syspolicy_update_policy_category', 'GRANT', 'PolicyAdministratorRole', 'dbo', 'R')
		,('sp_syspolicy_update_policy_category_subscription', 'GRANT', 'PolicyAdministratorRole', 'dbo', 'R')
		,('sp_syspolicy_update_target_set', 'GRANT', 'PolicyAdministratorRole', 'dbo', 'R')
		,('sp_syspolicy_update_target_set_level', 'GRANT', 'PolicyAdministratorRole', 'dbo', 'R')
		,('sp_syspolicy_verify_object_set_identifiers', 'GRANT', 'PolicyAdministratorRole', 'dbo', 'R')
		,('sp_sysmanagement_add_shared_registered_server', 'GRANT', 'ServerGroupAdministratorRole', 'dbo', 'R')
		,('sp_sysmanagement_add_shared_server_group', 'GRANT', 'ServerGroupAdministratorRole', 'dbo', 'R')
		,('sp_sysmanagement_delete_shared_registered_server', 'GRANT', 'ServerGroupAdministratorRole', 'dbo', 'R')
		,('sp_sysmanagement_delete_shared_server_group', 'GRANT', 'ServerGroupAdministratorRole', 'dbo', 'R')
		,('sp_sysmanagement_move_shared_registered_server', 'GRANT', 'ServerGroupAdministratorRole', 'dbo', 'R')
		,('sp_sysmanagement_move_shared_server_group', 'GRANT', 'ServerGroupAdministratorRole', 'dbo', 'R')
		,('sp_sysmanagement_rename_shared_registered_server', 'GRANT', 'ServerGroupAdministratorRole', 'dbo', 'R')
		,('sp_sysmanagement_rename_shared_server_group', 'GRANT', 'ServerGroupAdministratorRole', 'dbo', 'R')
		,('sp_sysmanagement_update_shared_registered_server', 'GRANT', 'ServerGroupAdministratorRole', 'dbo', 'R')
		,('sp_sysmanagement_update_shared_server_group', 'GRANT', 'ServerGroupAdministratorRole', 'dbo', 'R')
		,('sp_enum_login_for_proxy', 'GRANT', 'SQLAgentOperatorRole', 'dbo', 'R')
		,('sp_help_alert', 'GRANT', 'SQLAgentOperatorRole', 'dbo', 'R')
		,('sp_help_notification', 'GRANT', 'SQLAgentOperatorRole', 'dbo', 'R')
		,('sp_help_targetserver', 'GRANT', 'SQLAgentOperatorRole', 'dbo', 'R')
		,('sp_purge_jobhistory', 'GRANT', 'SQLAgentOperatorRole', 'dbo', 'R')
		,('sp_add_job', 'GRANT', 'SQLAgentUserRole', 'dbo', 'R')
		,('sp_add_jobschedule', 'GRANT', 'SQLAgentUserRole', 'dbo', 'R')
		,('sp_add_jobserver', 'GRANT', 'SQLAgentUserRole', 'dbo', 'R')
		,('sp_add_jobstep', 'GRANT', 'SQLAgentUserRole', 'dbo', 'R')
		,('sp_add_schedule', 'GRANT', 'SQLAgentUserRole', 'dbo', 'R')
		,('sp_addtask', 'GRANT', 'SQLAgentUserRole', 'dbo', 'R')
		,('sp_agent_get_jobstep', 'GRANT', 'SQLAgentUserRole', 'dbo', 'R')
		,('sp_attach_schedule', 'GRANT', 'SQLAgentUserRole', 'dbo', 'R')
		,('sp_check_for_owned_jobs', 'GRANT', 'SQLAgentUserRole', 'dbo', 'R')
		,('sp_check_for_owned_jobsteps', 'GRANT', 'SQLAgentUserRole', 'dbo', 'R')
		,('sp_delete_job', 'GRANT', 'SQLAgentUserRole', 'dbo', 'R')
		,('sp_delete_jobschedule', 'GRANT', 'SQLAgentUserRole', 'dbo', 'R')
		,('sp_delete_jobserver', 'GRANT', 'SQLAgentUserRole', 'dbo', 'R')
		,('sp_delete_jobstep', 'GRANT', 'SQLAgentUserRole', 'dbo', 'R')
		,('sp_delete_jobsteplog', 'GRANT', 'SQLAgentUserRole', 'dbo', 'R')
		,('sp_delete_schedule', 'GRANT', 'SQLAgentUserRole', 'dbo', 'R')
		,('sp_detach_schedule', 'GRANT', 'SQLAgentUserRole', 'dbo', 'R')
		,('sp_droptask', 'GRANT', 'SQLAgentUserRole', 'dbo', 'R')
		,('sp_enum_sqlagent_subsystems', 'GRANT', 'SQLAgentUserRole', 'dbo', 'R')
		,('sp_get_job_alerts', 'GRANT', 'SQLAgentUserRole', 'dbo', 'R')
		,('sp_get_jobstep_db_username', 'GRANT', 'SQLAgentUserRole', 'dbo', 'R')
		,('sp_get_sqlagent_properties', 'GRANT', 'SQLAgentUserRole', 'dbo', 'R')
		,('sp_help_category', 'GRANT', 'SQLAgentUserRole', 'dbo', 'R')
		,('sp_help_job', 'GRANT', 'SQLAgentUserRole', 'dbo', 'R')
		,('sp_help_jobactivity', 'GRANT', 'SQLAgentUserRole', 'dbo', 'R')
		,('sp_help_jobcount', 'GRANT', 'SQLAgentUserRole', 'dbo', 'R')
		,('sp_help_jobhistory', 'GRANT', 'SQLAgentUserRole', 'dbo', 'R')
		,('sp_help_jobhistory_full', 'GRANT', 'SQLAgentUserRole', 'dbo', 'R')
		,('sp_help_jobhistory_sem', 'GRANT', 'SQLAgentUserRole', 'dbo', 'R')
		,('sp_help_jobhistory_summary', 'GRANT', 'SQLAgentUserRole', 'dbo', 'R')
		,('sp_help_jobs_in_schedule', 'GRANT', 'SQLAgentUserRole', 'dbo', 'R')
		,('sp_help_jobschedule', 'GRANT', 'SQLAgentUserRole', 'dbo', 'R')
		,('sp_help_jobserver', 'GRANT', 'SQLAgentUserRole', 'dbo', 'R')
		,('sp_help_jobstep', 'GRANT', 'SQLAgentUserRole', 'dbo', 'R')
		,('sp_help_jobsteplog', 'GRANT', 'SQLAgentUserRole', 'dbo', 'R')
		,('sp_help_operator', 'GRANT', 'SQLAgentUserRole', 'dbo', 'R')
		,('sp_help_proxy', 'GRANT', 'SQLAgentUserRole', 'dbo', 'R')
		,('sp_help_schedule', 'GRANT', 'SQLAgentUserRole', 'dbo', 'R')
		,('sp_maintplan_subplans_by_job', 'GRANT', 'SQLAgentUserRole', 'dbo', 'R')
		,('sp_notify_operator', 'GRANT', 'SQLAgentUserRole', 'dbo', 'R')
		,('sp_start_job', 'GRANT', 'SQLAgentUserRole', 'dbo', 'R')
		,('sp_stop_job', 'GRANT', 'SQLAgentUserRole', 'dbo', 'R')
		,('sp_uniquetaskname', 'GRANT', 'SQLAgentUserRole', 'dbo', 'R')
		,('sp_update_job', 'GRANT', 'SQLAgentUserRole', 'dbo', 'R')
		,('sp_update_jobschedule', 'GRANT', 'SQLAgentUserRole', 'dbo', 'R')
		,('sp_update_jobstep', 'GRANT', 'SQLAgentUserRole', 'dbo', 'R')
		,('sp_update_schedule', 'GRANT', 'SQLAgentUserRole', 'dbo', 'R')
		,('sp_agent_get_jobstep', 'GRANT', 'TargetServersRole', 'dbo', 'R')
		,('sp_downloaded_row_limiter', 'GRANT', 'TargetServersRole', 'dbo', 'R')
		,('sp_enlist_tsx', 'GRANT', 'TargetServersRole', 'dbo', 'R')
		,('sp_help_jobschedule', 'GRANT', 'TargetServersRole', 'dbo', 'R')
		,('sp_help_jobstep', 'GRANT', 'TargetServersRole', 'dbo', 'R')
		,('sp_maintplan_subplans_by_job', 'GRANT', 'TargetServersRole', 'dbo', 'R')
		,('sp_sqlagent_check_msx_version', 'GRANT', 'TargetServersRole', 'dbo', 'R')
		,('sp_sqlagent_probe_msx', 'GRANT', 'TargetServersRole', 'dbo', 'R')
		,('sp_sqlagent_refresh_job', 'GRANT', 'TargetServersRole', 'dbo', 'R')
		,('fn_encode_sqlname_for_powershell', 'GRANT', 'UtilityCMRReader', 'dbo', 'R')
		,('fn_sysutility_get_is_instance_ucp', 'GRANT', 'UtilityCMRReader', 'dbo', 'R')
		,('fn_sysutility_ucp_get_aggregated_failure_count', 'GRANT', 'UtilityCMRReader', 'dbo', 'R')
		,('fn_sysutility_ucp_get_applicable_policy', 'GRANT', 'UtilityCMRReader', 'dbo', 'R')
		,('fn_sysutility_ucp_get_global_health_policy', 'GRANT', 'UtilityCMRReader', 'dbo', 'R')
		,('fn_sysutility_get_culture_invariant_conversion_style_internal', 'GRANT', 'UtilityIMRReader', 'dbo', 'R')
		,('fn_sysutility_mi_get_cpu_architecture_name', 'GRANT', 'UtilityIMRReader', 'dbo', 'R')
		,('fn_sysutility_mi_get_cpu_family_name', 'GRANT', 'UtilityIMRReader', 'dbo', 'R')
		,('sp_sysutility_mi_collect_dac_execution_statistics_internal', 'GRANT', 'UtilityIMRWriter', 'dbo', 'R')
		,('sp_sysutility_mi_get_dac_execution_statistics_internal', 'GRANT', 'UtilityIMRWriter', 'dbo', 'R')
 
	SET @va2033_sql = 'USE [?]
	INSERT INTO #va2033
	SELECT db_name,[permission_class],[schema],rules.object_name [object],[permission],[principal_type],rules.prin_name [principal]
	FROM (
		SELECT DB_NAME() db_name,perms.class_desc COLLATE database_default [permission_class],object_schema_name(major_id) COLLATE database_default [schema],object_name(major_id) COLLATE database_default object_name,perms.permission_name COLLATE database_default [permission],type_desc COLLATE database_default [principal_type],prin.name COLLATE database_default prin_name,state_desc COLLATE database_default state_desc,prin.type COLLATE database_default prin_type,user_name(grantor_principal_id) COLLATE database_default user_name
		FROM sys.database_permissions perms
		INNER JOIN sys.database_principals prin ON perms.grantee_principal_id = prin.principal_id
		WHERE permission_name IN (''EXECUTE'') AND perms.class = 1 AND [state] IN (''G'',''W'') AND grantee_principal_id NOT IN (DATABASE_PRINCIPAL_ID(''guest'') ,DATABASE_PRINCIPAL_ID(''public''))
	) rules
	LEFT JOIN #va2033_excludes ON rules.object_name = #va2033_excludes.object_name AND rules.state_desc = #va2033_excludes.state_desc AND rules.prin_name = #va2033_excludes.prin_name AND rules.user_name = #va2033_excludes.user_name AND rules.prin_type = #va2033_excludes.prin_type WHERE #va2033_excludes.object_name IS NULL'
 
	exec sp_MSforeachdb @va2033_sql
 
	IF EXISTS (SELECT 1 FROM #va2033)
		SELECT @@SERVERNAME AS sql_instance, 'VA2033' AS vulnerability, CONCAT('permission ',QUOTENAME([permission]),' in db ',QUOTENAME([db_name]),' should be revoked from ',QUOTENAME([principal])) AS [description]
		--,[db_name],[permission_class], [schema], [permission], [principal_type], [principal]
		FROM #va2033;
	ELSE
		SELECT @@SERVERNAME AS sql_instance, 'VA2033' AS vulnerability, '' AS [description]
		--,'' AS [db_name], '' AS [permission_class], '' AS [schema], '' AS [permission], '' AS [principal_type], '' AS [principal]
 
	DROP TABLE #va2033;
	DROP TABLE #va2033_excludes;
 
--VA2103 / FedRAMP / Unnecessary execute permissions on extended stored procedures should be revoked
	IF NOT EXISTS (SELECT OBJECT_NAME(major_id) AS [stored_procedure],dpr.[name] AS [principal]
			FROM sys.database_permissions AS dp
			INNER JOIN sys.database_principals AS dpr ON dp.grantee_principal_id = dpr.principal_id
			WHERE (major_id IN (OBJECT_ID('xp_dsninfo'),OBJECT_ID('xp_enumdsn'),OBJECT_ID('xp_enumerrorlogs'),OBJECT_ID('xp_eventlog'),OBJECT_ID('xp_getfiledetails'),OBJECT_ID('xp_getnetname')) OR (major_id IN (OBJECT_ID('xp_availablemedia'),OBJECT_ID('xp_dirtree'),OBJECT_ID('xp_enumerrorlogs'),OBJECT_ID('xp_enumgroups'),OBJECT_ID('xp_fixeddrives'),OBJECT_ID('xp_logevent'),OBJECT_ID('xp_loginconfig'),OBJECT_ID('xp_msver'),OBJECT_ID('xp_sprintf'),OBJECT_ID('xp_sscanf'),OBJECT_ID('xp_subdirs'),OBJECT_ID('xp_servicecontrol')) AND dp.grantee_principal_id = 0 )) AND dp.[type] = 'EX' AND [state] IN ('G','W'))
		SELECT @@SERVERNAME AS sql_instance, 'VA2103' AS vulnerability, '' AS [description]
			--,'' AS [principal],'' AS [stored_procedure],'' AS grantor
	ELSE
		SELECT @@SERVERNAME AS sql_instance, 'VA2103' AS vulnerability, CONCAT(QUOTENAME(dpr.[name]),' should have permission on ',QUOTENAME(OBJECT_NAME(major_id)),' revoked') AS [description]
				--,dpr.[name] AS [principal],OBJECT_NAME(major_id) AS [stored_procedure],USER_NAME(dp.grantor_principal_id) AS grantor
		FROM sys.database_permissions AS dp
		INNER JOIN sys.database_principals AS dpr ON dp.grantee_principal_id = dpr.principal_id
		WHERE (major_id IN (OBJECT_ID('xp_dsninfo'),OBJECT_ID('xp_enumdsn'),OBJECT_ID('xp_enumerrorlogs'),OBJECT_ID('xp_eventlog'),OBJECT_ID('xp_getfiledetails'),OBJECT_ID('xp_getnetname')) OR (major_id IN (OBJECT_ID('xp_availablemedia'),OBJECT_ID('xp_dirtree'),OBJECT_ID('xp_enumerrorlogs'),OBJECT_ID('xp_enumgroups'),OBJECT_ID('xp_fixeddrives'),OBJECT_ID('xp_logevent'),OBJECT_ID('xp_loginconfig'),OBJECT_ID('xp_msver'),OBJECT_ID('xp_sprintf'),OBJECT_ID('xp_sscanf'),OBJECT_ID('xp_subdirs'),OBJECT_ID('xp_servicecontrol')) AND dp.grantee_principal_id = 0 )) AND dp.[type] = 'EX' AND [state] IN ('G','W');
 
--VA2108 / FedRAMP / Minimal set of principals should be members of fixed high impact database roles
	USE tempdb;
	DECLARE @va2108_sql nvarchar(2000)
	IF OBJECT_ID('tempdb.dbo.#va2108', 'U') IS NOT NULL DROP TABLE #va2108;
 
	CREATE TABLE #va2108 ([db_name] sysname, [principal] sysname, [role] sysname, [principal_type] sysname)
 
	SET @va2108_sql='USE [?]
		INSERT INTO #va2108
		SELECT DB_NAME() AS [db_name]
		,USER_NAME(sr.member_principal_id) AS [principal]
		,USER_NAME(sr.role_principal_id) AS [role]
		,[type_desc] AS [principal_type]
		FROM sys.database_role_members AS sr
		INNER JOIN sys.database_principals sp ON sp.principal_id = sr.member_principal_id
		WHERE sr.role_principal_id IN (USER_ID(''bulkadmin''),USER_ID(''db_accessadmin''),USER_ID(''db_securityadmin''),USER_ID(''db_ddladmin''),USER_ID(''db_backupoperator'')) OR (sr.role_principal_id = USER_ID(''db_owner'') AND sr.member_principal_id <> USER_ID(''dbo''))'
 
	exec sp_MSforeachdb @va2108_sql
 
	IF EXISTS (SELECT 1 FROM #va2108)
		SELECT @@SERVERNAME AS sql_instance, 'VA2108' AS vulnerability, CONCAT('in db ',QUOTENAME([db_name]),' role ',QUOTENAME([role]),' of login ',QUOTENAME([principal],' should be either revoked or marked as baseline')) AS [description]
		--,[db_name],[principal],[role],[principal_type]
		FROM #va2108;
	ELSE
		SELECT @@SERVERNAME AS sql_instance, 'VA2108' AS vulnerability, '' AS [description]
		--,'' AS [db_name],'' AS [principal],'' AS [role],'' AS [principal_type]
 
	DROP TABLE #va2108;
 
--VA2109 / FedRAMP / Minimal set of principals should be members of fixed low impact database roles
	USE tempdb;
	DECLARE @va2109_sql nvarchar(2000)
	IF OBJECT_ID('tempdb.dbo.#va2109', 'U') IS NOT NULL DROP TABLE #va2109;
 
	CREATE TABLE #va2109 ([db_name] sysname, [principal] sysname, [role] sysname, [principal_type] sysname)
 
	SET @va2109_sql='USE [?]
		INSERT INTO #va2109
		SELECT DB_NAME() AS [db_name]
		,USER_NAME(sr.member_principal_id) AS [principal]
		,USER_NAME(sr.role_principal_id) AS [role]
		,[type_desc] AS [principal_type]
		FROM sys.database_role_members AS sr
		INNER JOIN sys.database_principals sp ON sp.principal_id = sr.member_principal_id
		WHERE sr.role_principal_id IN (USER_ID(''db_datareader''),USER_ID(''db_datawriter''),USER_ID(''db_denydatareader''),USER_ID(''db_denydatawriter''))'
 
	exec sp_MSforeachdb @va2109_sql
 
	IF EXISTS (SELECT 1 FROM #va2109)
		SELECT @@SERVERNAME AS sql_instance, 'VA2109' AS vulnerability, CONCAT('in db ',QUOTENAME([db_name]),' role ',QUOTENAME([role]),' of login ',QUOTENAME([principal],' should be either revoked or marked as baseline')) AS [description]
		--,[db_name],[principal],[role],[principal_type]
		FROM #va2109;
	ELSE
		SELECT @@SERVERNAME AS sql_instance, 'VA2109' AS vulnerability, '' AS [description]
		--,'' AS [db_name],'' AS [principal],'' AS [role],'' AS [principal_type]
 
	DROP TABLE #va2109;
 
--VA2110 / FedRAMP / Execute permissions to access the registry should be restricted
	IF NOT EXISTS (SELECT OBJECT_NAME(major_id) AS [stored_procedure],dpr.[name] AS [principal]
			FROM sys.database_permissions AS dp
			INNER JOIN sys.database_principals AS dpr ON dp.grantee_principal_id = dpr.principal_id
			WHERE major_id IN (OBJECT_ID('xp_regaddmultistring'),OBJECT_ID('xp_regdeletekey'),OBJECT_ID('xp_regdeletevalue'),OBJECT_ID('xp_regenumvalues'),OBJECT_ID('xp_regenumkeys'),OBJECT_ID('xp_regread'),OBJECT_ID('xp_regremovemultistring'),OBJECT_ID('xp_regwrite'),OBJECT_ID('xp_instance_regaddmultistring'),OBJECT_ID('xp_instance_regdeletekey'),OBJECT_ID('xp_instance_regdeletevalue'),OBJECT_ID('xp_instance_regenumkeys'),OBJECT_ID('xp_instance_regenumvalues'),OBJECT_ID('xp_instance_regread'),OBJECT_ID('xp_instance_regremovemultistring'),OBJECT_ID('xp_instance_regwrite')) AND dp.[type] = 'EX' AND [state] IN ('G','W'))
		SELECT @@SERVERNAME AS sql_instance, 'VA2110' AS vulnerability, '' AS [description]
		--,'' AS [principal],'' AS [stored_procedure],'' AS grantor
	ELSE
		SELECT @@SERVERNAME AS sql_instance, 'VA2110' AS vulnerability, CONCAT(QUOTENAME(dpr.[name]),' should have permission on ',QUOTENAME(OBJECT_NAME(major_id)),' revoked') AS [description]
			--,dpr.[name] AS [principal],OBJECT_NAME(major_id) AS [stored_procedure],USER_NAME(dp.grantor_principal_id) AS grantor
		FROM sys.database_permissions AS dp
		INNER JOIN sys.database_principals AS dpr ON dp.grantee_principal_id = dpr.principal_id
		WHERE major_id IN (OBJECT_ID('xp_regaddmultistring'),OBJECT_ID('xp_regdeletekey'),OBJECT_ID('xp_regdeletevalue'),OBJECT_ID('xp_regenumvalues'),OBJECT_ID('xp_regenumkeys'),OBJECT_ID('xp_regread'),OBJECT_ID('xp_regremovemultistring'),OBJECT_ID('xp_regwrite'),OBJECT_ID('xp_instance_regaddmultistring'),OBJECT_ID('xp_instance_regdeletekey'),OBJECT_ID('xp_instance_regdeletevalue'),OBJECT_ID('xp_instance_regenumkeys'),OBJECT_ID('xp_instance_regenumvalues'),OBJECT_ID('xp_instance_regread'),OBJECT_ID('xp_instance_regremovemultistring'),OBJECT_ID('xp_instance_regwrite')) AND dp.[type] = 'EX' AND [state] IN ('G','W')
 
--VA2114 / FedRAMP / Minimal set of principals should be members of high impact fixed server roles
	IF EXISTS (SELECT 1 FROM sys.server_role_members AS sr
			INNER JOIN sys.server_principals sp ON sp.principal_id = sr.member_principal_id
			WHERE sr.role_principal_id IN (SUSER_ID('sysadmin'),SUSER_ID('serveradmin'),SUSER_ID('setupadmin'),SUSER_ID('processadmin'),SUSER_ID('diskadmin'),SUSER_ID('dbcreator'),SUSER_ID('bulkadmin')) AND sp.principal_id != 1 AND NOT ((sr.role_principal_id = 3 AND sp.[name] = 'NT SERVICE\SQLWriter') OR (sr.role_principal_id = 3 AND sp.[name] = 'NT SERVICE\Winmgmt') OR (sr.role_principal_id = 3 AND sp.[name] = 'NT Service\MSSQLSERVER') OR (sr.role_principal_id = 3 AND sp.[name] = 'NT SERVICE\SQLSERVERAGENT') OR (sr.role_principal_id = 3 AND sp.[name] = 'NT Service\SQLIaaSExtension') OR (sr.role_principal_id = 3 AND sp.[name] = 'NT Service\HealthService') OR (sr.role_principal_id = 3 AND sp.[name] = 'NT Service\MSSQL' + ISNULL('$' + CONVERT(sysname, SERVERPROPERTY('InstanceName')), '')) OR (sr.role_principal_id = 3 AND sp.[name] = 'NT SERVICE\SQLAgent' + ISNULL('$' + CONVERT(sysname, SERVERPROPERTY('InstanceName')), ''))))
		SELECT
			@@SERVERNAME AS sql_instance, 'VA2114' AS vulnerability, CONCAT('role ',QUOTENAME(SUSER_NAME(sr.role_principal_id)),' of login ',QUOTENAME(sp.[name]),' should be either revoked or marked as baseline') AS [description]
			--,SUSER_NAME(sr.role_principal_id) AS [role] ,sp.[name] AS [principal]
		FROM sys.server_role_members AS sr
		INNER JOIN sys.server_principals sp ON sp.principal_id = sr.member_principal_id
		WHERE sr.role_principal_id IN (SUSER_ID('sysadmin'),SUSER_ID('serveradmin'),SUSER_ID('setupadmin'),SUSER_ID('processadmin'),SUSER_ID('diskadmin'),SUSER_ID('dbcreator'),SUSER_ID('bulkadmin')) AND sp.principal_id != 1 AND NOT ((sr.role_principal_id = 3 AND sp.[name] = 'NT SERVICE\SQLWriter') OR (sr.role_principal_id = 3 AND sp.[name] = 'NT SERVICE\Winmgmt') OR (sr.role_principal_id = 3 AND sp.[name] = 'NT Service\MSSQLSERVER') OR (sr.role_principal_id = 3 AND sp.[name] = 'NT SERVICE\SQLSERVERAGENT') OR (sr.role_principal_id = 3 AND sp.[name] = 'NT Service\SQLIaaSExtension') OR (sr.role_principal_id = 3 AND sp.[name] = 'NT Service\HealthService') OR (sr.role_principal_id = 3 AND sp.[name] = 'NT Service\MSSQL' + ISNULL('$' + CONVERT(sysname, SERVERPROPERTY('InstanceName')), '')) OR (sr.role_principal_id = 3 AND sp.[name] = 'NT SERVICE\SQLAgent' + ISNULL('$' + CONVERT(sysname, SERVERPROPERTY('InstanceName')), '')))
	ELSE
		SELECT @@SERVERNAME AS sql_instance, 'VA2114' AS vulnerability, '' AS [description]
		--,'' AS [role],'' AS [principal]
 
--VA2120 / CIS, FedRAMP / Features that may affect security should be disabled
	IF EXISTS (SELECT 1 FROM sys.configurations WHERE [name] IN ('allow updates','cross db ownership chaining','contained database authentication','remote access') AND CAST([value] AS int) = 1)
		SELECT @@SERVERNAME AS sql_instance, 'VA2120' AS vulnerability, CONCAT('feature ',QUOTENAME([name]),' should be disabled') AS [description]
			FROM sys.configurations WHERE [name] IN ('allow updates','cross db ownership chaining','contained database authentication','remote access') AND CAST([value] AS int) = 1;
	ELSE
		SELECT @@SERVERNAME AS sql_instance, 'VA2120' AS vulnerability, '' AS [description];
 
--VA2129 / CIS / Changes to signed modules should be authorized
	USE tempdb;
	DECLARE @va2129_sql nvarchar(2000)
	IF OBJECT_ID('tempdb.dbo.#va2129', 'U') IS NOT NULL DROP TABLE #va2129;
 
	CREATE TABLE #va2129 ([db_name] sysname, [module] nvarchar(256),[signing_object] sysname,[signing_object_owner] sysname NULL,[signing_object_thumbprint] varbinary(32),[last_definition_modify_date] datetime,[signing_object_type] nvarchar(128))
 
	SET @va2129_sql = 'USE [?]
	INSERT INTO #va2129
	SELECT
		DB_NAME() AS [db_name]
		,QUOTENAME(sc.name) + ''.'' + QUOTENAME(oj.name) AS [module]
		,IIF(ct.certificate_id IS NOT NULL, ct.name, ak.name) AS [signing_object]
		,dp.name AS [signing_object_owner]
		,cp.thumbprint AS [signing_object_thumbprint]
		,oj.modify_date AS [last_definition_modify_date]
		,IIF(ct.certificate_id IS NOT NULL, ''CERTIFICATE'', ''ASYMMETRIC KEY'') AS [signing_object_type]
	FROM sys.crypt_properties AS cp
	INNER JOIN sys.objects AS oj ON cp.major_id = oj.object_id
	INNER JOIN sys.schemas AS sc ON oj.schema_id = sc.schema_id
	INNER JOIN sys.sql_modules AS md ON md.object_id = cp.major_id
	LEFT OUTER JOIN sys.certificates AS ct ON cp.thumbprint = ct.thumbprint
	LEFT OUTER JOIN sys.asymmetric_keys AS ak ON cp.thumbprint = ak.thumbprint
	LEFT OUTER JOIN sys.database_principals AS dp ON (ct.sid = dp.sid OR ak.sid = dp.sid)
	WHERE oj.type IN (''P'',''FN'',''TR'') AND cp.class_desc = ''OBJECT_OR_COLUMN'''
 
	exec sp_MSforeachdb @va2129_sql
 
	IF NOT EXISTS (SELECT 1 FROM #va2129)
		SELECT @@SERVERNAME AS sql_instance, 'VA2129' AS vulnerability, '' AS [description]
			--,'' AS db_name, '' AS module, '' AS [signing_object], '' AS [signing_object_owner], '' AS [signing_object_thumbprint], '' AS [last_definition_modify_date], '' AS [signing_object_type]
	ELSE
		SELECT @@SERVERNAME AS sql_instance, 'VA2129' AS vulnerability, CONCAT('Module ',QUOTENAME(),' in database ',QUOTENAME(),' should be either signed or added as a baseline in Defender') AS [description]
			--,db_name, module, [signing_object], [signing_object_owner], [signing_object_thumbprint], [last_definition_modify_date], [signing_object_type]
		FROM #va2129
 
	DROP TABLE #va2129
 
--VA2201 / SQL logins with commonly used names should be disabled
	IF EXISTS (SELECT 1 FROM sys.sql_logins WHERE [type_desc] = 'SQL_LOGIN' AND is_disabled = 0 AND [name] IN ('401hk','Guest','admin','bizbox','bwsa','dazone','dsanc','gaibian','god','hbv7','kisadmin','kisadminnew1','mssqla','neterp','nt authority\anonymous logon','nxp','ps','repl_subscriber','sa','sqladmin','ss','su','sysdba','sysdbsa','test','uep','unierp','users','vice','youda'))
		SELECT @@SERVERNAME AS sql_instance, 'VA2201' AS vulnerability,CONCAT('login ',QUOTENAME([name]),' should be disabled or renamed') AS [description]
		--,[name] AS sql_login
		FROM sys.sql_logins WHERE [type_desc] = 'SQL_LOGIN' AND is_disabled = 0 AND [name] IN ('401hk','Guest','admin','bizbox','bwsa','dazone','dsanc','gaibian','god','hbv7','kisadmin','kisadminnew1','mssqla','neterp','nt authority\anonymous logon','nxp','ps','repl_subscriber','sa','sqladmin','ss','su','sysdba','sysdbsa','test','uep','unierp','users','vice','youda')
	ELSE
		SELECT @@SERVERNAME AS sql_instance, 'VA2201' AS vulnerability, '' AS [description]
		--,'' AS sql_login
