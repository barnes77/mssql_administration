/*
Created by: Mateusz Wierzbowski
Creation date: 
	v1.0	2021/07/27
	v2.0	2022/05/31
Aim: Get brief description of current instance's configs in order to replicate configs in new installation
*/
SET NOCOUNT ON;
 
IF OBJECT_ID('#dba_configs','U') IS NOT NULL BEGIN DROP TABLE #dba_configs; END
 
DECLARE @sql_data_root varchar(256), @back_path sql_variant
	
exec [master].dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',N'SOFTWARE\Microsoft\MSSQLServer\Setup',N'SQLDataRoot',@sql_data_root output
IF CAST(SERVERPROPERTY('ProductMajorVersion') AS int) >= 15
	BEGIN
		SELECT @back_path = SERVERPROPERTY('InstanceDefaultBackupPath')
	END
ELSE
	BEGIN
		exec [master].dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\MSSQLServer', N'BackupDirectory',@back_path output
	END
 
CREATE TABLE #dba_configs (
	server_name nvarchar(256)
	,[version] nvarchar(256)
	,sql_svc_acc nvarchar(256)
	,agent_svc_acc nvarchar(256)
	,[edition] nvarchar(256)
	,[authentication] nvarchar(256)
	,collation nvarchar(256)
	,data_root_dir nvarchar(256)
	,def_data_path nvarchar(256)
	,def_log_path nvarchar(256)
	,def_backup_path nvarchar(256)
);
 
INSERT INTO #dba_configs
SELECT
	@@SERVERNAME AS server_name
	,CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(256)) AS [version]
	,(SELECT service_account FROM sys.dm_server_services WHERE LOWER(servicename) LIKE '%sql server%' AND LOWER(servicename) NOT LIKE '%agent%') AS sql_svc_acc
	,(SELECT service_account FROM sys.dm_server_services WHERE LOWER(servicename) LIKE '%agent%') AS agent_svc_acc
	,CAST(SERVERPROPERTY('Edition') AS nvarchar(256)) AS [edition]
	,CASE
		WHEN SERVERPROPERTY('IsIntegratedSecurityOnly') = 0 THEN 'Mixed Mode Authentication'
		ELSE 'Windows Mode Authentication'
	END AS [authentication]
	,CAST(SERVERPROPERTY('Collation') AS nvarchar(256)) AS collation
	,@sql_data_root AS data_root_dir
	,CAST(SERVERPROPERTY('InstanceDefaultDataPath') AS nvarchar(256)) AS def_data_path
	,CAST(SERVERPROPERTY('InstanceDefaultLogPath') AS nvarchar(256)) AS def_log_path
	,CAST(@back_path AS nvarchar(256)) AS def_backup_path;
 
SELECT
	[parameter],[value]
FROM
	(SELECT
		server_name,[version],sql_svc_acc,agent_svc_acc,[edition],[authentication],collation,data_root_dir,def_data_path,def_log_path,def_backup_path
	FROM #dba_configs) AS unpivot_source
	UNPIVOT
	([value]	
	FOR [parameter]
	IN (server_name,[version],sql_svc_acc,agent_svc_acc,[edition],[authentication],collation,data_root_dir,def_data_path,def_log_path,def_backup_path)
	) AS unpivot_table;
 
DROP TABLE #dba_configs;
