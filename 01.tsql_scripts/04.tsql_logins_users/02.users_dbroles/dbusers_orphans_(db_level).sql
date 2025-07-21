/*
Created by: Mateusz Wierzbowski
Creation date: 2020/10/23
Aim: Get a list of orphaned users inside particular DB and create a script to alter it if there's a login with similar name
Compatibility: SQL2008+
*/
SET NOCOUNT ON;
--USE DBNAME
 
DECLARE @db_contained sysname;
SELECT @db_contained = containment_desc FROM sys.databases WHERE [name] = DB_NAME()
 
;WITH dba_orphaned_cte AS (	
	SELECT
		dbpri.[name] AS db_user
		,@db_contained AS db_is_contained
		,dbpri.[sid] AS db_user_sid
		,spri.[name] AS owner_login
		,spri.[sid] AS owner_login_sid
		,CASE
			WHEN dbpri.[name] LIKE '%\%' THEN (SELECT TOP 1 [name] FROM sys.server_principals WHERE [name] LIKE '%'+RIGHT(dbpri.[name],LEN(dbpri.[name])-CHARINDEX('\',dbpri.[name]))+'%')
			ELSE (SELECT TOP 1 [name] FROM sys.server_principals WHERE [name] LIKE '%'+dbpri.[name]+'%')
		END AS possible_owner
	FROM sys.database_principals AS dbpri
	LEFT JOIN sys.server_principals AS spri ON spri.[sid] = dbpri.[sid]
	WHERE 1=1 
		AND dbpri.type IN ('G','U','S') 
		AND dbpri.[name] NOT IN ('dbo','guest','INFORMATION_SCHEMA','sys','MS_DataCollectorInternalUser')
	AND spri.[name] IS NULL
)
 
SELECT
	db_user
	,db_is_contained
	--,db_user_sid
	,owner_login
	--,owner_login_sid
	,possible_owner
	,'USE '+DB_NAME()+'; ALTER USER '+db_user+' WITH LOGIN = '+possible_owner+';' AS query_to_map_orphan
FROM dba_orphaned_cte;
