/*
Created by: Mateusz Wierzbowski
Creation date: 2022/07/04
Aim: Gather information about all extended properties of databases
*/
USE tempdb;
SET NOCOUNT ON;
 
IF OBJECT_ID('#dba_extended_props','U') IS NOT NULL BEGIN DROP TABLE #dba_extended_props; END
 
CREATE TABLE #dba_extended_props (
	[db_name] sysname
	,class tinyint
	,class_desc nvarchar(60)
	,major_id int
	,minor_id int
	,[name] sysname
	,[value] sql_variant
);
 
DECLARE @sql_01 varchar(4000);
 
SET @sql_01 = 'USE [?]
INSERT INTO #dba_extended_props ([db_name], class, class_desc, major_id, minor_id, name, value)
SELECT
	DB_NAME() AS [db_name]
	,class
	,class_desc
	,major_id
	,minor_id
	,name
	,value
FROM sys.extended_properties;';
 
exec sp_MSforeachdb @sql_01;
 
SELECT
	[db_name]
	,class_desc
	,[name]
	,[value]
FROM #dba_extended_props
WHERE 1=1
	AND class_desc = 'DATABASE'
--	AND [name] = ''
--	AND [name] LIKE '%%'
ORDER BY [db_name],[name];
 
DROP TABLE #dba_extended_props;
 
/*
--query to add property to a database
USE [database]
exec sp_addextendedproperty @name='PROPERTY_NAME',@value='PROPERTY_VALUE'
*/
