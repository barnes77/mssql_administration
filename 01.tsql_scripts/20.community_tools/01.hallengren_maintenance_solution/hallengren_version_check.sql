/*
Created by: Mateusz Wierzbowski
Creation date: 2022/03/22
Aim: Check what is the current version of Ola Hallengren's script either in master or DBA database
Note: Hallengren introduced timestamp of the version only in 2018-06-10 14:25:42,
	so for earlier versions the modify_date of the object is given as version
*/
 

USE [tempdb]
IF OBJECT_ID('#hallengren_ver','U') IS NOT NULL BEGIN DROP TABLE #hallengren_ver; END
 
DECLARE @query01 nvarchar(2000), @query02 nvarchar(2000);
 
CREATE TABLE #hallengren_ver (
	[database_name] sysname
	,[procedure] sysname
	,[create_date] datetime
	,[modify_date] datetime
	,[version_date] datetime
);
 
SET @query01 = 'USE [master]
INSERT INTO #hallengren_ver
SELECT
	DB_NAME() AS [database_name]
	,sp.[name] [procedure]
	,so.create_date
	,so.modify_date
	,CASE
		WHEN so.create_date < ''2018-06-10 14:25:42.999'' AND so.modify_date < ''2018-06-10 14:25:42.999'' THEN so.modify_date
		WHEN CHARINDEX(''--// Version: '',OBJECT_DEFINITION(so.[object_id])) > 0
			THEN SUBSTRING(OBJECT_DEFINITION(so.[object_id]),CHARINDEX(''--// Version: '',OBJECT_DEFINITION(so.[object_id]))+LEN(''--// Version: '')+1,19)
	END AS version_date
FROM sys.procedures AS sp
LEFT JOIN sys.objects AS so ON sp.[object_id] = so.[object_id]
WHERE sp.[name] IN (''CommandExecute'',''DatabaseBackup'',''DatabaseIntegrityCheck'',''IndexOptimize'')';
 
SET @query02 = 'USE [DBA]
INSERT INTO #hallengren_ver
SELECT
	DB_NAME() AS [database_name]
	,sp.[name] [procedure]
	,so.create_date
	,so.modify_date
	,CASE
		WHEN so.create_date < ''2018-06-10 14:25:42.999'' AND so.modify_date < ''2018-06-10 14:25:42.999'' THEN so.modify_date
		WHEN CHARINDEX(''--// Version: '',OBJECT_DEFINITION(so.[object_id])) > 0
			THEN SUBSTRING(OBJECT_DEFINITION(so.[object_id]),CHARINDEX(''--// Version: '',OBJECT_DEFINITION(so.[object_id]))+LEN(''--// Version: '')+1,19)
	END AS version_date
FROM sys.procedures AS sp
LEFT JOIN sys.objects AS so ON sp.[object_id] = so.[object_id]
WHERE sp.[name] IN (''CommandExecute'',''DatabaseBackup'',''DatabaseIntegrityCheck'',''IndexOptimize'')';
 
exec (@query01);
 
IF EXISTS (SELECT 1 FROM sys.databases WHERE [name] = 'DBA' AND state_desc = 'ONLINE')
	BEGIN
		exec (@query02);
	END
 
SELECT
	[database_name]
	,[procedure]
	,CASE
		WHEN version_date IS NOT NULL THEN version_date
		WHEN version_date IS NULL THEN modify_date
	END AS hallengren_version
FROM #hallengren_ver;
 
DROP TABLE #hallengren_ver;
