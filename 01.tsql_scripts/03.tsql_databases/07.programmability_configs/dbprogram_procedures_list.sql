/*
Created by: Mateusz Wierzbowski
Creation date: 2020/02/24
Aim: List all stored procedures inside SQL instance
V2.0: 2021/10/01
*/
USE tempdb;
SET NOCOUNT ON;
 
IF OBJECT_ID('#proc_check','U') IS NOT NULL BEGIN DROP TABLE #proc_check; END
 
CREATE TABLE #proc_check (
	[database_name] sysname
	,[schema] sysname
	,proc_name sysname
	,proc_id int
	,query nvarchar(max)
);
 
exec sp_MSforeachdb
'USE [?]
INSERT INTO #proc_check
SELECT
	DB_NAME() AS [database_name]
	,SCHEMA_NAME([schema_id]) AS [schema]
	,[name] AS proc_name
	,OBJECT_ID([name]) AS proc_id
	,OBJECT_DEFINITION(OBJECT_ID([name])) AS query
FROM sys.procedures';
 
SELECT
	[database_name]
	,[schema]
	,proc_name
	,query AS proc_query
FROM #proc_check
WHERE 1=1
--	AND proc_name LIKE '%execute%' --Find procedure with specific name
--	AND query LIKE '%execute%' --Find procedure with specific query
DROP TABLE #proc_check;
