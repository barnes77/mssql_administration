/*
Created by: Mateusz Wierzbowski
Creation date: 2020/03/21-2020/03/22
Aim: Perform audit of logins/user permissions
Version: 1.0
Compatibility: SQL2012+
*/
USE tempdb;
SET NOCOUNT ON;
 
IF OBJECT_ID('#choose_db_table') IS NOT NULL BEGIN DROP TABLE #choose_db_table; END
IF OBJECT_ID('#login_results_table') IS NOT NULL BEGIN DROP TABLE #login_results_table; END
IF OBJECT_ID('#user_results_table') IS NOT NULL BEGIN DROP TABLE #user_results_table; END
 
DECLARE @include_system_db tinyint, @include_simple_rec tinyint, @include_bulk_rec tinyint, @include_full_rec tinyint, @include_multi_user tinyint,
@include_single_user tinyint, @include_restricted_user tinyint, @include_emergency tinyint, @include_contained tinyint, @db_name_pattern sysname,
@include_not_ag tinyint, @include_ag tinyint, @include_ag_primary tinyint, @include_ag_secondary tinyint, @query nvarchar(2000);
 
/*INCLUDE OR EXCLUDE DATABASES BASED ON PROPERTIES - Choose 1 to include or 0 to exclude // Choose name pattern*/
SET @include_system_db = 1			SET @include_single_user = 1
SET @include_simple_rec = 1			SET @include_restricted_user = 1
SET @include_bulk_rec = 1			SET @include_multi_user = 1
SET @include_full_rec = 1			SET @include_emergency = 1
SET @include_not_ag = 1				SET @include_contained = 1
SET @include_ag = 1
SET @include_ag_primary = 1
SET @include_ag_secondary = 1
SET @db_name_pattern = '';
 
/*DEFINITION OF RESULTS TABLE*/
CREATE TABLE #user_results_table (
	[database_name] sysname
	,[user_name] sysname NULL
	,db_permission sysname
	,user_sid varbinary(85)
	,user_type nvarchar(60)
);
CREATE TABLE #choose_db_table (
	[name] sysname
	,is_user_db tinyint
	,is_simple tinyint
	,is_bulk tinyint
	,is_full tinyint
	,is_multi_user tinyint
	,is_single_user tinyint
	,is_restricted_user tinyint
	,is_read_only tinyint
	,is_online tinyint
	,is_emergency tinyint
	,is_offline tinyint
	,is_restoring tinyint
	,is_contained tinyint
	,is_not_contained tinyint
	,is_not_ag_joined tinyint
	,is_ag_joined tinyint
	,is_ag_primary tinyint
	,is_ag_secondary tinyint
);
CREATE TABLE #login_results_table (
	login_name sysname
	,[login_type] nvarchar(60)
	,server_role sysname
	,login_sid varbinary(85)
	,is_disabled int
);
 
/*CHOOSE A QUERY TO BE RUN AGAINST EACH DB - IN CASE OF CHANGES YOU NEED TO CHANGE DEFINTION OF TABLE WITH RESULTS*/
SET @query = '
SELECT
	DB_NAME() AS [database_name]
	,dbpri1.[name] AS [user_name]
	,ISNULL(dbpri2.[name],''public'') AS db_permission
	,dbpri1.[sid] AS user_sid
	,dbpri1.[type_desc] AS user_type
FROM sys.database_principals AS dbpri1
LEFT JOIN sys.database_role_members AS dbrm ON dbpri1.principal_id = dbrm.member_principal_id
LEFT JOIN sys.database_principals AS dbpri2 ON dbpri2.principal_id = dbrm.role_principal_id
WHERE dbpri1.[type] <> ''R'' AND dbpri1.[name] NOT IN (''dbo'',''guest'',''sys'',''INFORMATION_SCHEMA'')
 
SELECT DB_NAME() AS [database_name]
	 ,dbpri1.[name] AS [user_name]
	 ,dbper.state_desc+'': ''+dbper.permission_name+'' on ''+sobj.[name] COLLATE Latin1_General_CI_AS +'' (''+sobj.[type_desc] COLLATE Latin1_General_CI_AS +'')'' AS db_permission
	 ,dbpri1.[sid] AS user_sid
	 ,dbpri1.[type_desc] AS user_type
FROM sys.database_permissions AS dbper
LEFT JOIN sys.objects AS sobj ON dbper.major_id = sobj.object_id
LEFT JOIN sys.database_principals AS dbpri1 ON dbper.grantee_principal_id = dbpri1.principal_id
LEFT JOIN sys.database_principals AS dbpri2 ON dbper.grantor_principal_id = dbpri2.principal_id
WHERE dbpri1.[type_desc] <> ''DATABASE_ROLE'' AND sobj.name IS NOT NULL
 
SELECT
	DB_NAME() AS [database_name]
	,SCHEMA_OWNER AS [user_name]
	,''OWNERSHIP OF SCHEMA: ''+SCHEMA_NAME AS db_permission
	,dbpri.[sid] AS user_sid
	,dbpri.[type_desc] AS user_type
FROM information_schema.schemata AS issch
LEFT JOIN sys.database_principals AS dbpri ON issch.schema_owner = dbpri.[name]
WHERE dbpri.[type] <> ''R'' AND dbpri.[name] NOT IN (''dbo'',''guest'',''sys'',''INFORMATION_SCHEMA'')
';
 
/*DO NOT CHANGE THE QUERY BELOW*/
INSERT INTO #choose_db_table
SELECT
	sdb.[name]
	,CASE WHEN sdb.database_id > 4 THEN 1 ELSE 0 END AS [is_user_db]
	,CASE WHEN sdb.recovery_model = 3 THEN 1 ELSE 0 END AS [is_simple]
	,CASE WHEN sdb.recovery_model = 2 THEN 1 ELSE 0 END AS [is_bulk]
	,CASE WHEN sdb.recovery_model = 1 THEN 1 ELSE 0 END AS [is_full]
	,CASE WHEN sdb.user_access = 0 THEN 1 ELSE 0 END AS [is_multi_user]
	,CASE WHEN sdb.user_access = 1 THEN 1 ELSE 0 END AS [is_single_user]
	,CASE WHEN sdb.user_access = 2 THEN 1 ELSE 0 END AS [is_restricted_user]
	,CASE WHEN sdb.is_read_only = 1 THEN 1 ELSE 0 END AS [is_read_only]
	,CASE WHEN sdb.[state] = 0 THEN 1 ELSE 0 END AS [is_online]
	,CASE WHEN sdb.[state] = 5 THEN 1 ELSE 0 END AS [is_emergency]
	,CASE WHEN sdb.[state] IN (6,10) THEN 1 ELSE 0 END AS [is_offline]
	,CASE WHEN sdb.[state] = 1 THEN 1 ELSE 0 END AS [is_restoring]
	,CASE WHEN sdb.containment = 1 THEN 1 ELSE 0 END AS [is_contained]
	,CASE WHEN sdb.containment = 0 THEN 1 ELSE 0 END AS [is_not_contained]
	,CASE WHEN adc.group_id IS NULL THEN 1 ELSE 0 END AS is_not_ag_joined
	,CASE WHEN adc.group_id IS NOT NULL THEN 1 ELSE 0 END AS is_ag_joined
	,CASE WHEN dm_hars.[role] = 1 THEN 1 ELSE 0 END AS is_ag_primary
	,CASE WHEN dm_hars.[role] = 2 THEN 1 ELSE 0 END AS is_ag_secondary
FROM sys.databases AS sdb
LEFT JOIN sys.availability_databases_cluster AS adc ON sdb.name = adc.database_name
LEFT JOIN sys.dm_hadr_availability_replica_states AS dm_hars ON dm_hars.group_id = adc.group_id;
 
DECLARE @db_name sysname, @final_query nvarchar(2000);
 
DECLARE db_crsr CURSOR LOCAL FAST_FORWARD FOR
	SELECT [name] FROM #choose_db_table
	WHERE is_user_db + @include_system_db >= 1 AND is_bulk + is_full + @include_simple_rec >= 1 AND is_simple + is_full + @include_bulk_rec >= 1
	AND is_simple + is_bulk + @include_full_rec >= 1 AND is_restricted_user + is_multi_user + @include_single_user >= 1
	AND is_single_user + is_multi_user + @include_restricted_user >= 1 AND is_single_user + is_restricted_user + @include_multi_user >= 1
	AND is_online + @include_emergency >= 1 AND is_not_contained + @include_contained >= 1 AND is_ag_joined + @include_not_ag >= 1
	AND is_not_ag_joined + @include_ag >= 1 AND is_ag_secondary + @include_ag_primary >= 1 AND is_ag_primary + @include_ag_secondary >= 1
	AND [name] Like '%'+@db_name_pattern+'%' AND is_offline <> 1 AND is_restoring <> 1
 
OPEN db_crsr;
	FETCH NEXT FROM db_crsr INTO @db_name
	WHILE @@FETCH_STATUS = 0
	BEGIN
	SET @final_query = 'USE ['+@db_name+']; '+@Query
/*INCLUDE CHANGES OF A DEFINITION OF RESULTS TABLE HERE*/
	INSERT INTO #user_results_table
	exec (@final_query);
	FETCH NEXT FROM db_crsr INTO @db_name;
END
CLOSE db_crsr;
DEALLOCATE db_crsr;
 
/*QUERY DBOs*/
INSERT INTO #user_results_table
SELECT
	sdb.[name] AS [database_name]
	,spri.[name] AS [user_name]
	,'dbo' AS db_permission
	,spri.[sid] AS user_sid
	,spri.[type_desc] AS user_type
FROM sys.databases AS sdb
LEFT JOIN sys.server_principals AS spri ON sdb.owner_sid = spri.[sid]
 
/*QUERY SERVER ROLES*/
INSERT INTO #login_results_table
SELECT
	spri1.[name] AS login_name
	,spri1.[type_desc] AS [login_type]
	,ISNULL(spri2.[name],'public') AS server_role
	,spri1.[sid] AS login_sid
	,spri1.is_disabled AS is_disabled
FROM sys.server_principals AS spri1
LEFT JOIN sys.server_role_members AS srm ON spri1.principal_id = srm.member_principal_id
LEFT JOIN sys.server_principals AS spri2 ON spri2.principal_id = srm.role_principal_id
WHERE spri1.[type] NOT IN ('R','C')
 
/*GET ALL RESULTS FOR SELECT QUERIES*/
SELECT
	lrt.login_name AS login_name
	,CASE
	WHEN lrt.is_disabled = 1 THEN 'disabled'
	WHEN lrt.is_disabled = 0 THEN 'enabled'
	ELSE '' END AS login_status
	,lrt.[login_type] AS [login_type]
	,lrt.server_role AS server_role
	,urt.[database_name] AS [database_name]
	,urt.[user_name] AS [user_name]
	,urt.db_permission AS db_permission
FROM #login_results_table AS lrt
FULL OUTER JOIN #user_results_table AS urt ON lrt.login_sid = urt.user_sid
ORDER BY lrt.login_name, urt.[database_name]
 
/*LIST DATABASE EXCLUDED FROM THE QUERY*/
 
SELECT
	[name] AS db_excluded
	,DATABASEPROPERTYEX([name],'Status') AS [status]
	,DATABASEPROPERTYEX([name],'UserAccess') AS user_access
	,DATABASEPROPERTYEX([name],'Updateability') AS updateability
FROM #choose_db_table
WHERE is_user_db + @include_system_db < 1 OR is_bulk + is_full + @include_simple_rec < 1 OR is_simple + is_full + @include_bulk_rec < 1 OR is_simple + is_bulk + @include_full_rec < 1 OR is_restricted_user + is_multi_user + @include_single_user < 1
	OR is_single_user + is_multi_user + @include_restricted_user < 1 OR is_single_user + is_restricted_user + @include_multi_user < 1 OR is_online + @include_emergency < 1 OR is_not_contained + @include_contained < 1
	OR is_ag_joined + @include_not_ag < 1 OR is_not_ag_joined + @include_ag < 1 OR is_ag_secondary + @include_ag_primary < 1 OR is_ag_primary + @include_ag_secondary < 1 OR [name] NOT Like '%'+@db_name_pattern+'%'
	OR is_offline = 1 OR is_restoring = 1
 
DROP TABLE #choose_db_table;
DROP TABLE #user_results_table;
DROP TABLE #login_results_table;
