/*
Created by: Mateusz Wierzbowski
Creation date: 2022/03/24
Aim: Gather information about objects in particular schema across whole instance
*/
 
USE tempdb;
 
IF OBJECT_ID('#dba_objects','U') IS NOT NULL BEGIN DROP TABLE #dba_objects; END
 
CREATE TABLE #dba_objects (
	[database_name] sysname
	,[name] sysname
	,[object_id] int
	,[schema_name] sysname
	,type_desc nvarchar(60)
	,create_date datetime
	,modify_date datetime
);
 
DECLARE @query nvarchar(2000);
 
SET @query =
'USE [?]
INSERT INTO #dba_objects
SELECT
	DB_NAME() AS [database_name]
	,sobj.[name]
	,sobj.object_id
	,SCHEMA_NAME(sobj.schema_id) AS [schema_name]
	,sobj.type_desc
	,sobj.create_date
	,sobj.modify_date
FROM sys.objects AS sobj
LEFT JOIN sys.schemas AS ssch ON sobj.schema_id = ssch.schema_id
WHERE ssch.[name] = ''schema_name'''; --change schema name here
 
exec sp_MSforeachDB @query;
 
SELECT * FROM #dba_objects;
 
DROP TABLE #dba_objects;
