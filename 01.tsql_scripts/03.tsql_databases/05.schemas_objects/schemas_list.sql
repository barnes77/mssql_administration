USE tempdb;
SET NOCOUNT ON;
 
IF OBJECT_ID('#dba_schemata_check','U') IS NOT NULL BEGIN DROP TABLE #dba_schemata_check; END
 
CREATE TABLE #dba_schemata_check (
	[database_name] sysname
	,catalog_name sysname
	,[schema_name] nvarchar(128)
	,schema_owner nvarchar(128)
);
 
exec sp_MSforeachdb
'USE [?];
INSERT INTO #dba_schemata_check
SELECT
	DB_Name() AS [database_name]
	,catalog_name
	,[schema_name]
	,schema_owner
FROM INFORMATION_SCHEMA.SCHEMATA';
 
SELECT
	*
FROM #dba_schemata_check
WHERE 1=1
--	AND [schema_owner] = '' --Lookup specific owner
;
 
DROP TABLE #dba_schemata_check;
