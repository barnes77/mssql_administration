/*
Created by: Mateusz Wierzbowski
Creation date: 2020/03/27
Aim: List tables
Compatibility: SQL2005+
*/
USE tempdb;
SET NOCOUNT ON;
 
IF OBJECT_ID('#dba_quick_check','U') IS NOT NULL BEGIN DROP TABLE #dba_quick_check; END
 
CREATE TABLE #dba_quick_check (
	[database_name] sysname
	,[table] nvarchar(384)
	,[type] varchar(10)
);
 
exec sp_MSforeachdb
	'USE [?]
	INSERT INTO #dba_quick_check
	SELECT
		DB_NAME() AS [database_name]
		,table_catalog+''.''+table_schema+''.''+table_name AS [table]
		,table_type AS [type]
	FROM information_schema.tables';
 
SELECT
	[database_name]
	,[table]
	,[type]
FROM #dba_quick_check
WHERE 1=1
--	AND [type] LIKE '%%' --Possible types: VIEW, BASE TABLE
ORDER BY [database_name], [table];
DROP TABLE #dba_quick_check;
