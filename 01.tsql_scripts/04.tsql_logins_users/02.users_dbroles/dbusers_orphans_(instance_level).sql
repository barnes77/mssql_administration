/*
Created by: Mateusz Wierzbowski
Creation date: 2020/10/23
Aim: Get a list of orphaned users for whole instance and create a script to alter it if there's a login with similar name
Compatibility: SQL2008+
*/
USE tempdb;
SET NOCOUNT ON;
 
IF OBJECT_ID('#dba_orphans','U') IS NOT NULL BEGIN DROP TABLE #dba_orphans; END
 
CREATE TABLE #dba_orphans (	
	[database_name] sysname
	,db_user sysname
	,owning_login sysname NULL
	,possible_owner sysname NULL
);
 
exec sp_MSforeachdb '
USE [?]
INSERT INTO #dba_orphans
SELECT
	DB_NAME() AS [database_name]
	,dbpri.[name] AS db_user
	,spri.[name] AS owning_login
	,CASE
		WHEN dbpri.[name] LIKE ''%\%'' THEN (SELECT TOP 1 [name] FROM sys.server_principals WHERE [name] LIKE ''%''+RIGHT(dbpri.[name],LEN(dbpri.name)-CHARINDEX(''\'',dbpri.[name]))+''%'')
		ELSE (SELECT TOP 1 [name] FROM sys.server_principals WHERE [name] LIKE ''%''+dbpri.[name]+''%'')
		END AS possible_owner
FROM sys.database_principals AS dbpri
LEFT JOIN sys.server_principals AS spri ON spri.sid = dbpri.sid
WHERE 1=1 
	AND dbpri.[type] IN (''G'',''U'',''S'') 
	AND dbpri.[name] NOT IN (''dbo'',''guest'',''INFORMATION_SCHEMA'',''sys'',''MS_DataCollectorInternalUser'')
AND spri.[name] IS NULL';
 
SELECT
	do.[database_name]
	,sdb.containment_desc AS DBContainmentLevel
	,do.db_user
	,do.owning_login
	,do.possible_owner
	,'USE '+do.[database_name]+'; ALTER USER '+do.db_user+' WITH LOGIN = '+do.possible_owner+';' AS [QueryFixOrphanedUser]
FROM #dba_orphans AS do
LEFT JOIN sys.databases AS sdb ON do.[database_name] = sdb.name;
 
DROP TABLE #dba_orphans;
