/*
Created by: Mateusz Wierzbowski
Creation date: 2019/06/25
Aim: List tables and views in databases
 
Corrections:
	2020/10/12 - Put results for each database into one table
*/
USE tempdb;
SET NOCOUNT ON;
 
IF OBJECT_ID('#dba_quick_check_tables','U') IS NOT NULL BEGIN DROP TABLE #dba_quick_check_tables; END
 
CREATE TABLE #dba_quick_check_tables (	
	table_catalog nvarchar(128)
	,table_schema nvarchar(128)
	,table_name sysname
	,table_type nvarchar(128)
);
 
DECLARE @query nvarchar(max)
	,@version int = CAST(SUBSTRING(CONVERT(varchar(40),SERVERPROPERTY('ProductVersion')),1,CHARINDEX('.',CONVERT(varchar(40),SERVERPROPERTY('ProductVersion')))-1) AS int)
 
IF @version > 8
	BEGIN
		SET @query = '
		USE [?]
		INSERT INTO #dba_quick_check_tables
		SELECT *
		FROM information_schema.tables
		WHERE table_type = ''BASE TABLE''
		--this is for views
		--OR table_type = ''VIEW''
		--here you can type databasename
		--AND table_catalog=''dbName''
		';
	END
	ELSE
	BEGIN
		SET @query = '
		USE [?]
		INSERT INTO #dba_quick_check_tables
		SELECT * FROM sysobjects WHERE xtype IN(''U'',
		--these are for internal/system tables:
		--''IT'',''S'',
		--this is for views
		--''V''
		)';
	END
exec sp_MSforeachDB @query;
 
SELECT
	*
FROM #dba_quick_check_tables
WHERE 1=1
	AND table_catalog LIKE '%%'
--	AND table_schema LIKE '%%'
--	AND table_name LIKE '%%'
--	AND table_type LIKE '%%'
ORDER BY table_catalog, table_schema, table_name;
 
DROP TABLE #dba_quick_check_tables;
