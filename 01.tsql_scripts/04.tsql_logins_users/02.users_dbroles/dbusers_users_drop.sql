/*
Created by: Mateusz Wierzbowski
Creation date: 2022/03/24
Aim: drop user across the instance with either transferring schema to db_owner or dropping it
*/
 
USE tempdb;
 
IF OBJECT_ID('#dba_users','U') IS NOT NULL BEGIN DROP TABLE #dba_users; END
 
CREATE TABLE #dba_users (
	[database_name] sysname
	,[name] sysname
	,cmd_schema_drop nvarchar(2000)
	,cmd_schema_transfer nvarchar(2000)
);
 
DECLARE @query nvarchar(2000)
 
SET @query =
'USE [?]
INSERT INTO #dba_users ([database_name],[name],cmd_schema_drop,cmd_schema_transfer )
SELECT
	DB_NAME() AS [database_name]
	,name
	,CONCAT(''USE '',QUOTENAME(DB_NAME()),''; DROP SCHEMA '',QUOTENAME(name), ''; DROP USER '',QUOTENAME(name))
	,CONCAT(''USE '',QUOTENAME(DB_NAME()),''; ALTER AUTHORIZATION ON SCHEMA:: '',QUOTENAME(name), '' TO db_owner; DROP USER '',QUOTENAME(name))
FROM sys.database_principals
WHERE [name] = ''username'''; --change user name here
 
exec sp_MSforeachDB @query;
 
SELECT * FROM #dba_users;
 
DROP TABLE #dba_users;
