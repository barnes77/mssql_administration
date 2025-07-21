/*
Created by: Mateusz Wierzbowski
Creation date: 2021/10/04
Modifidaction date: 2022/06/29
Aim: Gather info about principals db level
*/
 
USE tempdb;
SET NOCOUNT ON;
 
--Part00: Cleanup temp tables
	IF OBJECT_ID('#dba_dbs','U') IS NOT NULL BEGIN DROP TABLE #dba_dbs; END
	IF OBJECT_ID('#dba_db_users','U') IS NOT NULL BEGIN DROP TABLE #dba_db_users; END
	IF OBJECT_ID('#dba_db_roles','U') IS NOT NULL BEGIN DROP TABLE #dba_db_roles; END
	IF OBJECT_ID('##dba_db_users_total','U') IS NOT NULL BEGIN DROP TABLE ##dba_db_users_total; END
 
--Part01: Declare variables
DECLARE
	@role_name sysname, @role_agg varchar(4000)
	,@db_name sysname, @db_role_agg varchar(4000)
	,@query1 varchar(4000), @query2 varchar(4000);
 
--Part02: Create temp tables
	--Create table with names of databases that can be queried
	CREATE TABLE #dba_dbs (
		[database_name] sysname
	);
	--Create table with names of user roles
	CREATE TABLE #dba_db_users (
		[database_name] sysname
		,[db_user] sysname
		,temp_val tinyint
		,[sid] sql_variant
		,db_role_name sysname NULL
	);
	--Create table with names of database roles
	CREATE TABLE #dba_db_roles (
		db_role_name sysname
	);
 
--Part 03: Gather info about database roles
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
		db_role_name
	FROM #dba_db_users
	WHERE db_role_name IS NOT NULL;
 
	--Gather names of all database_roles into one variable
	SELECT @db_role_agg = ''
	SELECT @db_role_agg = @db_role_agg + ', ' + db_role_name FROM (SELECT DISTINCT db_role_name FROM #dba_db_roles ) AS t ORDER BY t.db_role_name ASC
	SELECT @db_role_agg = SUBSTRING(@db_role_agg,3,LEN(@db_role_agg)-2);
 
	--Create a query with pivot for all db_roles
	SET @query1 = 'SELECT
		[database_name]
		,db_user
		,'+@db_role_agg+'
	INTO ##dba_db_users_total
	FROM (
		SELECT
			[database_name]
			,db_user
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
 
--Prat04: Get finall results
SELECT
	*
FROM ##dba_db_users_total
WHERE 1=1
--	AND db_user LIKE '%%'
--	AND db_user NOT LIKE '%%'
--	AND [database_name] LIKE '%%'
--	AND [database_name] NOT LIKE '%%'
ORDER BY [database_name],db_user;
 
DROP TABLE #dba_dbs;
DROP TABLE #dba_db_users;
DROP TABLE #dba_db_roles;
DROP TABLE ##dba_db_users_total;
