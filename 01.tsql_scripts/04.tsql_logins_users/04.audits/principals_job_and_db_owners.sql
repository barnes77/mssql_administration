/*
Created by: Mateusz Wierzbowski
Creation date: 2018/01/29
Aim: Auditing all owners of all DBs and jobs that are enabled
*/
USE tempdb;
SET NOCOUNT ON;
 
IF OBJECT_ID('#obsolete_owners','U') IS NOT NULL BEGIN DROP TABLE #obsolete_owners; END
 
CREATE TABLE #obsolete_owners (
	[object_type] nvarchar(50)
	,[name] sysname
	,[owner] sysname NULL
	,correction_query nvarchar(260) NULL
);
 
INSERT INTO #obsolete_owners
SELECT
	'job' AS [object_type]
	,sobj.[name] AS [name]
	,CASE
		WHEN sobj.owner_sid IS NULL THEN 'no_owner'
		WHEN spri.[name] IS NULL THEN 'ad_group_member'
		ELSE spri.[name]
	END AS [owner]
	,CASE
		WHEN sobj.owner_sid IS NULL THEN
			'USE msdb;'+'exec dbo.sp_update_job @job_name = N'''+sobj.[name]+''', @owner_login_name = N'''+(SELECT [name] FROM sys.server_principals WHERE principal_id = 1)+''';'
		ELSE ''
	END AS correction_query
FROM msdb.dbo.sysjobs AS sobj
LEFT JOIN sys.server_principals AS spri ON sobj.owner_sid = spri.sid
WHERE sobj.enabled = 1;
 
INSERT INTO #obsolete_owners
SELECT
	'database' AS [object_type]
	,sdb.[name] AS [name]
	,CASE
		WHEN sdb.owner_sid IS NULL THEN 'no_owner'
		WHEN spri.[name] IS NULL THEN 'ad_group_member'
		ELSE spri.[name]
	END AS [owner]
	,CASE
		WHEN sdb.owner_sid IS NULL THEN 'ALTER AUTHORIZATION ON DATABASE::'+sdb.name +' TO'+(SELECT [name] FROM sys.server_principals WHERE principal_id = 1)+';'
		ELSE ''
	END AS correction_query
FROM sys.databases AS sdb
LEFT JOIN sys.server_principals AS spri ON spri.sid = sdb.owner_sid
 
SELECT
	[object_type]
	,[name]
	,[owner]
	,correction_query
FROM #obsolete_owners
 
WHERE 1=1
	AND [owner] LIKE '%%' --Provide name of the owner here or remove it to get all owners
ORDER BY [object_type],[name]
 
DROP TABLE #obsolete_owners;
