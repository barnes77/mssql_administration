/*
Creation Date: 2020/03/21-2020/03/22
Created By: Mateusz Wierzbowski
Aim: Alternative for sp_MSforeachDB
Version: 1.1
Compatibility: SQL2012+
Updates:
	2021/10/01 - rewritten in snake_case notation
*/
USE tempdb;
SET NOCOUNT ON;
 
IF OBJECT_ID('#choose_db_table','U') IS NOT NULL BEGIN DROP TABLE #choose_db_table; END
IF OBJECT_ID('#user_results_table','U') IS NOT NULL BEGIN DROP TABLE #user_results_table; END
IF OBJECT_ID('#login_results_table','U') IS NOT NULL BEGIN DROP TABLE #login_results_table; END
IF OBJECT_ID('#results_for_the_command','U') IS NOT NULL BEGIN DROP TABLE #results_for_the_command; END
 
CREATE TABLE #login_results_table (
	login_name sysname
	,[login_type] nvarchar(60)
	,server_role sysname
	,login_sid varbinary(85)
	,is_disabled int
);
CREATE TABLE #results_for_the_command (
	login_name sysname
	,login_status nvarchar(20)
	,[login_type] nvarchar(85)
	,server_role sysname
	,[database_name] sysname
	,[user_name] sysname
	,db_permission nvarchar(200)
	,row_no int
);
CREATE TABLE #user_results_table (
	[database_name] sysname
	,[user_name] sysname
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
	,is_not_ad_joined tinyint
	,is_ag_joined tinyint
	,is_ag_primary tinyint
	,is_ag_secondary tinyint
);
 
USE tempdb;
DECLARE @include_system_db tinyint, @include_simple_rec tinyint, @include_bulk_rec tinyint, @include_full_rec tinyint,
@include_multi_user tinyint, @include_single_user tinyint, @include_restricted_user tinyint, @include_emergency tinyint,
@include_contained tinyint, @db_name_pattern sysname, @include_not_ag tinyint, @include_ag tinyint, @include_ag_primary tinyint,
@include_ag_secondary tinyint, @query nvarchar(2000), @principal_pattern_name sysname;
 
/*INCLUDE OR EXCLUDE DATABASES BASED ON PROPERTIES - Choose 1 to include or 0 to exclude // Choose name pattern*/
SET @include_system_db = 1			 	SET @include_single_user = 1
SET @include_simple_rec = 1					SET @include_restricted_user = 1
SET @include_bulk_rec = 1				 SET @include_multi_user = 1
SET @include_full_rec = 1				 SET @include_emergency = 1
SET @include_not_ag = 1						SET @include_contained = 1
SET @include_ag = 1							SET @principal_pattern_name = 'login_name' --!!! Use name of account, not %DOMAIN%\%ACCOUNT%
SET @include_ag_primary = 1
SET @include_ag_secondary = 0
SET @db_name_pattern = '';
 
/*CHOOSE A QUERY TO BE RUN AGAINST EACH DB - IN CASE OF CHANGES YOU NEED TO CHANGE DEFINTION OF TABLE WITH RESULTS*/
SET @query = '
SELECT
	DB_NAME() AS [database_name]
	,dbperrin1.name AS [user_name]
	,ISNULL(dbperrin2.name,''public'') AS db_permission
	,dbperrin1.sid AS user_sid
	,dbperrin1.type_desc AS user_type
FROM sys.database_principals AS dbperrin1
LEFT JOIN sys.database_role_members AS dbrm ON dbperrin1.principal_id = dbrm.member_principal_id
LEFT JOIN sys.database_principals AS dbperrin2 ON dbperrin2.principal_id = dbrm.role_principal_id
WHERE dbperrin1.type <> ''R'' AND dbperrin1.name NOT IN (''dbo'',''guest'',''sys'',''INFORMATION_SCHEMA'')
 
SELECT DB_NAME() AS [database_name]
	 ,dbpri1.name AS [user_name]
	 ,dbper.state_desc+'': ''+dbper.permission_name+'' on ''+sobj.Name COLLATE Latin1_General_CI_AS +'' (''+sobj.type_desc COLLATE Latin1_General_CI_AS +'')'' AS db_permission
	 ,dbpri1.sid AS user_sid
	 ,dbpri1.type_desc AS user_type
FROM sys.database_permissions AS dbper
LEFT JOIN sys.objects AS sobj ON dbper.major_id = sobj.object_id
LEFT JOIN sys.database_principals AS dbpri1 ON dbper.grantee_principal_id = dbpri1.principal_id
LEFT JOIN sys.database_principals AS dbpri2 ON dbper.grantor_principal_id = dbpri2.principal_id
WHERE dbpri1.type_desc <> ''DATABASE_ROLE'' AND sobj.name IS NOT NULL
 
SELECT
	DB_NAME() AS [database_name]
	,SCHEMA_OWNER AS [user_name]
	,''OWNERSHIP OF SCHEMA: ''+SCHEMA_NAME AS db_permission
	,dbpri.sid AS user_sid
	,dbpri.type_desc AS user_type
FROM information_schema.schemata AS issch
LEFT JOIN sys.database_principals AS dbpri ON issch.schema_owner = dbpri.name
WHERE dbpri.type <> ''R'' AND dbpri.name NOT IN (''dbo'',''guest'',''sys'',''INFORMATION_SCHEMA'')
';
 
/*DO NOT CHANGE THE QUERY BELOW*/
INSERT INTO #choose_db_table
SELECT
	sdb.[name]
	,CASE WHEN sdb.database_id > 4 THEN 1 ELSE 0 END AS is_user_db
	,CASE WHEN sdb.recovery_model = 3 THEN 1 ELSE 0 END AS is_simple
	,CASE WHEN sdb.recovery_model = 2 THEN 1 ELSE 0 END AS is_bulk
	,CASE WHEN sdb.recovery_model = 1 THEN 1 ELSE 0 END AS is_full
	,CASE WHEN sdb.user_access = 0 THEN 1 ELSE 0 END AS is_multi_user
	,CASE WHEN sdb.user_access = 1 THEN 1 ELSE 0 END AS is_single_user
	,CASE WHEN sdb.user_access = 2 THEN 1 ELSE 0 END AS is_restricted_user
	,CASE WHEN sdb.is_read_only = 1 THEN 1 ELSE 0 END AS is_read_only
	,CASE WHEN sdb.[state] = 0 THEN 1 ELSE 0 END AS is_online
	,CASE WHEN sdb.[state] = 5 THEN 1 ELSE 0 END AS is_emergency
	,CASE WHEN sdb.[state] IN (6,10) THEN 1 ELSE 0 END AS is_offline
	,CASE WHEN sdb.[state] = 1 THEN 1 ELSE 0 END AS is_restoring
	,CASE WHEN sdb.containment = 1 THEN 1 ELSE 0 END AS is_contained
	,CASE WHEN sdb.containment = 0 THEN 1 ELSE 0 END AS is_not_contained
	,CASE WHEN adc.group_id IS NULL THEN 1 ELSE 0 END AS is_not_ad_joined
	,CASE WHEN adc.group_id IS NOT NULL THEN 1 ELSE 0 END AS is_ag_joined
	,CASE WHEN dm_hars.[role] = 1 THEN 1 ELSE 0 END AS is_ag_primary
	,CASE WHEN dm_hars.[role] = 2 THEN 1 ELSE 0 END AS is_ag_secondary
FROM sys.databases AS sdb
LEFT JOIN sys.availability_databases_cluster AS adc ON sdb.[name] = adc.database_name
LEFT JOIN sys.dm_hadr_availability_replica_states AS dm_hars ON dm_hars.group_id = adc.group_id;
 
DECLARE @db_name sysname, @final_query nvarchar(2000);
 
DECLARE crsr CURSOR LOCAL FAST_FORWARD FOR
	SELECT [name] FROM #choose_db_table
	WHERE is_user_db + @include_system_db >= 1 AND is_bulk + is_full + @include_simple_rec >= 1
	AND is_simple + is_full + @include_bulk_rec >= 1 AND is_simple + is_bulk + @include_full_rec >= 1
	AND is_restricted_user + is_multi_user + @include_single_user >= 1 AND is_single_user + is_multi_user + @include_restricted_user >= 1
	AND is_single_user + is_restricted_user + @include_multi_user >= 1 AND is_online + @include_emergency >= 1
	AND is_not_contained + @include_contained >= 1 AND is_ag_joined + @include_not_ag >= 1
	AND is_not_ad_joined + @include_ag >= 1 AND is_ag_secondary + @include_ag_primary >= 1
	AND is_ag_primary + @include_ag_secondary >= 1 AND [name] Like '%'+@db_name_pattern+'%'
	AND is_offline <> 1 AND is_restoring <> 1
 
OPEN crsr;
	FETCH NEXT FROM crsr INTO @db_name
	WHILE @@FETCH_STATUS = 0
	BEGIN
	SET @final_query = 'USE ['+@db_name+'] '+CHAR(13)+@query
/*INCLUDE CHANGES OF A DEFINITION OF RESULTS TABLE*/
	INSERT INTO #user_results_table
	exec (@final_query);
	FETCH NEXT FROM crsr INTO @db_name;
END
CLOSE crsr;
DEALLOCATE crsr;
 
/*QUERY DBOs*/
INSERT INTO #user_results_table
SELECT
	sdb.[name] AS [database_name]
	,spri.[name] AS [user_name]
	,'dbo' AS db_permission
	,spri.[sid] AS user_sid
	,spri.[type_desc] AS user_type
FROM sys.databases AS sdb
LEFT JOIN sys.server_principals AS spri ON sdb.owner_sid = spri.sid;
 
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
WHERE spri1.type NOT IN ('R','C');
 
/*JOIN RESULTS*/
INSERT INTO #results_for_the_command
SELECT
	ISNULL(lrt.login_name,'') AS login_name
	,CASE
	WHEN lrt.is_disabled = '1' THEN 'disabled'
	WHEN lrt.is_disabled = '0' THEN 'enabled'
	ELSE '' END AS login_status
	,ISNULL(lrt.[login_type],'') AS [login_type]
	,ISNULL(lrt.server_role,'') AS server_role
	,ISNULL(urt.[database_name],'') AS [database_name]
	,ISNULL(urt.[user_name],'') AS [user_name]
	,ISNULL(urt.db_permission,'') AS db_permission
	,ROW_NUMBER() OVER (PARTITION BY urt.[database_name] ORDER BY urt.[database_name]) AS row_no
FROM #login_results_table AS lrt
FULL OUTER JOIN #user_results_table AS urt ON lrt.login_sid = urt.user_sid
WHERE lrt.login_name LIKE '%'+@principal_pattern_name+'%' OR urt.[user_name] LIKE '%'+@principal_pattern_name+'%'
ORDER BY login_name, [database_name];
 
/*DECLARE VARIABLES FOR THE OUTPUT*/
DECLARE @dropquery1 nvarchar(2000), @dropquery2 nvarchar(2000), @dropquery3 nvarchar(2000), @dropquery4 nvarchar(2000), @dropquery5 nvarchar(2000);
 
/*CREATE COMMAND TO CHANGE DATABASE OWNERSHIPS*/
SET @dropquery1 = '';
SELECT @dropquery1 = @dropquery1+CHAR(10)+'USE ['+[name]+']'+CHAR(10)+'GO'+CHAR(10)+'ALTER AUTHORIZATION ON DATABASE::['+[name]+'] TO ['+SUSER_SNAME(0x01)+']'+CHAR(10)+'GO'
	FROM sys.databases AS x
	WHERE SUSER_SNAME(x.owner_sid) LIKE '%'+@principal_pattern_name+'%' AND DATABASEPROPERTYEX(name,'Updateability') = 'READ_WRITE';
 
/*CREATE COMMAND TO CHANGE SCHEMATA OWNERSHIPS*/
SET @dropquery2 = '';
SELECT @dropquery2 = @dropquery2+CHAR(10)+'USE ['+[database_name]+']'+CHAR(10)+'GO'+CHAR(10)+'ALTER AUTHORIZATION ON SCHEMA::['+REPLACE(db_permission,'OWNERSHIP OF SCHEMA: ','')+'] TO [dbo]'+CHAR(10)+'GO'
	FROM #results_for_the_command AS x
	WHERE x.db_permission LIKE '%SCHEMA%' AND DATABASEPROPERTYEX([database_name],'Updateability') = 'READ_WRITE';
 
/*CREATE COMMAND TO DROP MAPPED USERS*/
SET @dropquery3 = '';
SELECT @dropquery3 = @dropquery3+CHAR(10)+'USE ['+[database_name]+']'+CHAR(10)+'GO'+CHAR(10)+'DROP USER ['+[user_name]+']'+CHAR(10)+'GO'
	FROM #results_for_the_command AS x
	WHERE x.db_permission NOT LIKE '%SCHEMA%' AND x.row_no = '1' AND x.db_permission <> 'dbo' AND DATABASEPROPERTYEX([database_name],'Updateability') = 'READ_WRITE';
 
/*CREATE COMMAND TO CHANGE JOB OWNERS*/
SET @dropquery4 = '';
SELECT @dropquery4 = @dropquery4+CHAR(10)+'USE [msdb]'+CHAR(10)+'GO'+CHAR(10)+'exec msdb.dbo.sp_update_job @job_id=N'''+CONVERT(nvarchar(2000),x.job_id)+''','+CHAR(10)+'@owner_login_name=N'''+SUSER_SNAME(0x01)+''''+CHAR(10)+'GO'
	FROM msdb.dbo.sysjobs AS x
	LEFT JOIN sys.server_principals AS y ON x.owner_sid = y.sid
	WHERE y.name LIKE '%'+@principal_pattern_name+'%';
 
/*CREATE COMMAND TO DROP LOGIN*/
SET @dropquery5 = '';
SELECT @dropquery5 = @dropquery5+CHAR(10)+'USE [master]'+CHAR(10)+'GO'+CHAR(10)+'DROP LOGIN ['+name+']'+CHAR(10)+'GO'
	FROM sys.server_principals
	WHERE name LIKE '%'+@principal_pattern_name+'%';
 
PRINT '/*'
PRINT 'Query generated on '+CONVERT(varchar,GETDATE(),20)
PRINT 'Query is automatized and needs to be thouroughly verified before running. Possibly some corrections might be needed.'
PRINT 'Please note that changing db_owner will cause a temporary lock on the database'+CHAR(10)
PRINT 'First Step: Change db owners'
PRINT 'No command will be printed if the principal does not own databases'
PRINT '!!! by default it will be changed to default SA !!! - make corrections if needed'
PRINT 'ReadOnly DBs excluded'
PRINT '*/'
PRINT @dropquery1
PRINT CHAR(10)+'/*'
PRINT 'Second Step: Change authorization on schemas'
PRINT 'No command will be printed if the principal does not own schemas'
PRINT '!!! by default it will be changed to dbo !!! - make corrections if needed'
PRINT 'ReadOnly DBs excluded'
PRINT '*/'
PRINT @dropquery2
PRINT CHAR(10)+'/*'
PRINT 'Third Step: Drop mapped users'
PRINT 'No command will be printed if the principal has no mapped users'
PRINT 'ReadOnly DBs excluded'
PRINT '*/'
PRINT @dropquery3
PRINT CHAR(10)+'/*'
PRINT 'Fourth Step: Changed ownership of jobs'
PRINT 'No command will be printed if the principal does not own any job'
PRINT '*/'
PRINT @dropquery4
PRINT CHAR(10)+'/*'
PRINT 'Fifth Step: Drop login'
PRINT '*/'
PRINT @dropquery5
 

DROP TABLE #choose_db_table;
DROP TABLE #user_results_table;
DROP TABLE #login_results_table;
DROP TABLE #results_for_the_command;
