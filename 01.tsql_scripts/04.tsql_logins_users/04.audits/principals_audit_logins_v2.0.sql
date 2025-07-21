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
	IF OBJECT_ID('##dba_logins_total','U') IS NOT NULL BEGIN DROP TABLE ##dba_logins_total; END
	
--Part01: Declare variables
DECLARE
	@role_name sysname, @role_agg varchar(4000)
	,@db_name sysname, @db_role_agg varchar(4000)
	,@query1 varchar(4000), @query2 varchar(4000);
 
--Part02: Create temp tables
	--Create table with names of server roles
	CREATE TABLE #dba_srv_roles (
		[name] sysname
	);
	--Create a table for pivoted results
	CREATE TABLE #dba_logins (
		login_name sysname
		,temp_val tinyint
		,role_name sysname NULL
		,[sid] sql_variant
	);
 
--Part03: Gather info about server roles
	--Put names of server roles into #dba_srv_roles
	INSERT INTO #dba_srv_roles
	SELECT
		QUOTENAME([name],'[]')
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
	SELECT @role_agg = @role_agg + ', ' + [name] FROM (SELECT DISTINCT [name] FROM #dba_srv_roles ) AS t ORDER BY t.[name] ASC
	SELECT @role_agg = SUBSTRING(@role_agg,3,LEN(@role_agg)-2);
 
	--Create a query with pivot for all server_roles
	SET @query1 = 'SELECT
		login_name
		,'+@role_agg+'
	INTO ##dba_logins_total
	FROM (
		SELECT
			login_name
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
 
--Prat04: Get finall results
SELECT
	*
FROM ##dba_logins_total
WHERE 1=1
--	AND login_name LIKE '%%'
--	AND login_name NOT LIKE '%%'
ORDER BY login_name;
 
DROP TABLE #dba_srv_roles;
DROP TABLE #dba_logins;
DROP TABLE ##dba_logins_total;
