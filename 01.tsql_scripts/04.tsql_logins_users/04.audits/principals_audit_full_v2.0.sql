/*
Created by: Mateusz Wierzbowski
Creation date: 2021/10/04
Modifidaction date: 2022/06/29
Aim: Gather info about principals on instance and db level
*/
 
USE tempdb;
SET NOCOUNT ON;
 
--Part00: Cleanup temp tables
	IF OBJECT_ID('#dba_srv_roles','U') IS NOT NULL BEGIN DROP TABLE #dba_srv_roles; END
	IF OBJECT_ID('#dba_logins','U') IS NOT NULL BEGIN DROP TABLE #dba_logins; END
	IF OBJECT_ID('#dba_dbs','U') IS NOT NULL BEGIN DROP TABLE #dba_dbs; END
	IF OBJECT_ID('#dba_db_users','U') IS NOT NULL BEGIN DROP TABLE #dba_db_users; END
	IF OBJECT_ID('#dba_db_roles','U') IS NOT NULL BEGIN DROP TABLE #dba_db_roles; END
	IF OBJECT_ID('##dba_logins_total','U') IS NOT NULL BEGIN DROP TABLE ##dba_logins_total; END
	IF OBJECT_ID('##dba_db_users_total','U') IS NOT NULL BEGIN DROP TABLE ##dba_db_users_total; END
	IF OBJECT_ID('##principals_total','U') IS NOT NULL BEGIN DROP TABLE ##principals_total; END
 
--Part01: Declare variables
DECLARE
	@role_name sysname, @role_agg varchar(4000)
	,@db_name sysname, @db_role_agg varchar(4000)
	,@query1 varchar(4000), @query2 varchar(4000);
 
--Part02: Create temp tables
	--Create table with names of server roles
	CREATE TABLE #dba_srv_roles (
		[name] sysname
		,principal_id int
	);
	--Create a table for pivoted results
	CREATE TABLE #dba_logins (
		login_name sysname
		,temp_val tinyint
		,role_name sysname NULL
		,[sid] sql_variant
	);
	--Create table with names of databases that can be queried
	CREATE TABLE #dba_dbs (
		[database_name] sysname
	);
	--Create table with names of user roles
	CREATE TABLE #dba_db_users (
		[database_name] sysname
		,[db_user] sysname
		,principal_id int
		,temp_val tinyint
		,[sid] sql_variant
		,db_role_name sysname NULL
	);
	--Create table with names of database roles
	CREATE TABLE #dba_db_roles (
		db_role_name sysname
		,principal_id int
	);
 
--Part03: Gather info about server roles
	--Put names of server roles into #dba_srv_roles
	INSERT INTO #dba_srv_roles
	SELECT
		QUOTENAME([name],'[]')
		,principal_id
	FROM sys.server_principals
	WHERE [type] = 'R' AND sid <> 0x02;
 
	--Put names of logins into #dba_logins
	INSERT INTO #dba_logins
	SELECT
		spp1.[name] AS login_name
		,1 AS temp_val --needed for pivot
		,spp2.[name] AS role_name
		,spp1.[sid] AS [sid]
	FROM sys.server_principals AS spp1
	LEFT JOIN sys.server_role_members AS sdrm ON spp1.principal_id = sdrm.member_principal_id
	LEFT JOIN sys.server_principals AS spp2 ON spp2.principal_id = sdrm.role_principal_id
	WHERE spp1.[type] IN ('S','U','G') AND spp1.[name] NOT LIKE '##%' AND spp1.[name] NOT LIKE 'NT %';
 
	--Gather names of all server roles into one variable
	SELECT @role_agg = ''
	SELECT @role_agg = @role_agg + ', ' + [name] FROM (SELECT DISTINCT [name], principal_id FROM #dba_srv_roles ) AS t ORDER BY t.principal_id ASC
	SELECT @role_agg = SUBSTRING(@role_agg,3,LEN(@role_agg)-2);
 
	--Create a query with pivot for all server_roles
	SET @query1 = 'SELECT
		login_name
		,[sid]
		,'+@role_agg+'
	INTO ##dba_logins_total
	FROM (
		SELECT
			login_name
			,[sid]
			,temp_val
			,role_name
		FROM #dba_logins
		) AS pivot_source
		PIVOT (
			MAX(temp_val)
				--column that will be pivoted
				FOR role_name
			IN ('+@role_agg+')
		) AS pivot_table'
 
	exec (@query1);
 
--Part 04: Gather info about database roles
	--Get names of databases that can be queried
	INSERT INTO #dba_dbs
	SELECT
		[name]
	FROM sys.databases
	WHERE [state] = 0 AND [database_id] <> 2;
 
	--Create a query to get overview of database_roles for all databases
	DECLARE db_crsr CURSOR LOCAL FAST_FORWARD FOR
	SELECT [database_name] FROM #dba_dbs
	OPEN db_crsr;
	FETCH NEXT FROM db_crsr INTO @db_name
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @query2 =
		'USE '+QUOTENAME(@db_name)+
		'INSERT INTO #dba_db_users
		SELECT
			DB_NAME() AS [database_name]
			,sdp1.name AS db_user
			,sdp2.principal_id
			,1 AS temp_val
			,sdp1.[sid] AS [sid]
			,sdp2.name AS db_role_name
		FROM sys.database_principals AS sdp1
		LEFT JOIN sys.database_role_members AS sdrm ON sdp1.principal_id = sdrm.member_principal_id
		LEFT JOIN sys.database_principals AS sdp2 ON sdp2.principal_id = sdrm.role_principal_id
		WHERE sdp1.[type] <> ''R'' AND sdp1.[name] NOT IN (''INFORMATION_SCHEMA'',''sys'',''guest'')
		'
		exec (@query2);
 
	FETCH NEXT FROM db_crsr INTO @db_name
	END;
	CLOSE db_crsr;
	DEALLOCATE db_crsr;
 
	--Get list of all db_roles in all databases
	INSERT INTO #dba_db_roles
	SELECT DISTINCT
		db_role_name, principal_id
	FROM #dba_db_users
	WHERE db_role_name IS NOT NULL;
 
	--Gather names of all database_roles into one variable
	SELECT @db_role_agg = ''
	SELECT @db_role_agg = @db_role_agg + ', ' + db_role_name FROM (SELECT DISTINCT db_role_name, principal_id FROM #dba_db_roles ) AS t ORDER BY t.principal_id ASC
	SELECT @db_role_agg = SUBSTRING(@db_role_agg,3,LEN(@db_role_agg)-2);
 
	--Create a query with pivot for all db_roles
	SET @query1 = 'SELECT
		[database_name]
		,db_user
		,[sid]
		,'+@db_role_agg+'
	INTO ##dba_db_users_total
	FROM (
		SELECT
			[database_name]
			,db_user
			,[sid]
			,temp_val
			,db_role_name
		FROM #dba_db_users
		) AS pivot_source
		PIVOT (
			MAX(temp_val)
				--column that will be pivoted
				FOR db_role_name
			IN ('+@db_role_agg+')
		) AS pivot_table'
 
	exec (@query1);
 
--Prat05: Join tables and get finall results
	--Join results for logins and users
	SET @query2 = 'SELECT
		dlt.login_name
		,'+@role_agg+'
		,ddut.[database_name]
		,ddut.db_user
		,'+@db_role_agg+'
	INTO ##principals_total
	FROM ##dba_logins_total AS dlt
	LEFT JOIN ##dba_db_users_total AS ddut ON dlt.[sid] = ddut.[sid]
	ORDER BY dlt.login_name ASC, ddut.[database_name] ASC, ddut.db_user'
 
	exec (@query2);
 
SELECT
	*
FROM ##principals_total
WHERE 1=1
--	AND login_name LIKE '%%'
--	AND login_name NOT LIKE '%%'
--	AND db_user LIKE '%%'
--	AND db_user NOT LIKE '%%'
--	AND [database_name] LIKE '%%'
--	AND [database_name] NOT LIKE '%%'
ORDER BY login_name, [database_name];
 
DROP TABLE #dba_srv_roles;
DROP TABLE #dba_logins;
DROP TABLE #dba_dbs;
DROP TABLE #dba_db_users;
DROP TABLE #dba_db_roles;
DROP TABLE ##dba_logins_total;
DROP TABLE ##dba_db_users_total;
DROP TABLE ##principals_total;
