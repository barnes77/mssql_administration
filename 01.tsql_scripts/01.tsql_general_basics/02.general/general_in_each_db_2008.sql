/*
Creation Date: 2020/03/21-2020/03/22
Created By: Mateusz Wierzbowski
Aim: Alternative for sp_MSforeachDB
Version: 1.1
Compatibility: SQL2008+
*/
USE tempdb;
SET NOCOUNT ON;
 
IF OBJECT_ID('#choose_db_table','U') IS NOT NULL BEGIN DROP TABLE #choose_db_table; END
IF OBJECT_ID('#user_results_table','U') IS NOT NULL BEGIN DROP TABLE #user_results_table; END
 
DECLARE @include_system_db tinyint, @include_simple_rec tinyint, @include_bulk_rec tinyint, @include_full_rec tinyint,
@include_multi_user tinyint, @include_single_user tinyint, @include_restricted_user tinyint, @include_emergency tinyint,
@include_contained tinyint, @db_name_pattern sysname, @include_not_ag tinyint, @include_ag tinyint, @include_ag_primary tinyint, @include_ag_secondary tinyint, @query nvarchar(2000);
 
/*INCLUDE OR EXCLUDE DATABASES BASED ON PROPERTIES - Choose 1 to include or 0 to exclude // Choose name pattern*/
SET @include_system_db = 1				SET @include_single_user = 1
SET @include_simple_rec = 1				SET @include_restricted_user = 1
SET @include_bulk_rec = 1				SET @include_multi_user = 1
SET @include_full_rec = 1				SET @include_emergency = 1
SET @include_not_ag = 1					SET @include_contained = 1
SET @include_ag = 1
SET @include_ag_primary = 1
SET @include_ag_secondary = 1
SET @db_name_pattern = '';
 
/*CHOOSE A QUERY TO BE RUN AGAINST EACH DB - IN CASE OF CHANGES YOU NEED TO CHANGE DEFINTION OF TABLE WITH RESULTS*/
SET @query = '
INSERT INTO #user_results_table
SELECT DB_NAME()
';
 
/*DEFINITION OF RESULTS TABLE*/
CREATE TABLE #user_results_table ( [db_name] sysname );
 
/*DO NOT CHANGE THE QUERY BELOW*/
CREATE TABLE #choose_db_table ( [name] sysname, is_user_db tinyint, is_simple tinyint, is_bulk tinyint, is_full tinyint, is_multi_user tinyint, is_single_user tinyint, is_restricted_user tinyint, is_read_only tinyint, is_online tinyint, is_emergency tinyint, is_offline tinyint, is_restoring tinyint, is_contained tinyint, is_not_contained tinyint, is_not_ag_joined tinyint, is_ag_joined tinyint, is_ag_primary tinyint, is_ag_secondary tinyint);
INSERT INTO #choose_db_table
SELECT
	[name]
	,CASE WHEN [database_id] > 4 THEN 1 ELSE 0 END AS [is_user_db]
	,CASE WHEN recovery_model = 3 THEN 1 ELSE 0 END AS [is_simple]
	,CASE WHEN recovery_model = 2 THEN 1 ELSE 0 END AS [is_bulk]
	,CASE WHEN recovery_model = 1 THEN 1 ELSE 0 END AS [is_full]
	,CASE WHEN user_access = 0 THEN 1 ELSE 0 END AS [is_multi_user]
	,CASE WHEN user_access = 1 THEN 1 ELSE 0 END AS [is_single_user]
	,CASE WHEN user_access = 2 THEN 1 ELSE 0 END AS [is_restricted_user]
	,CASE WHEN is_read_only = 1 THEN 1 ELSE 0 END AS [is_read_only]
	,CASE WHEN [state] = 0 THEN 1 ELSE 0 END AS [is_online]
	,CASE WHEN [state] = 5 THEN 1 ELSE 0 END AS [is_emergency]
	,CASE WHEN [state] IN (6,10) THEN 1 ELSE 0 END AS [is_offline]
	,CASE WHEN [state] = 1 THEN 1 ELSE 0 END AS [is_restoring]
	,0 AS [is_contained]
	,0 AS [is_not_contained]
	,0 AS is_not_ag_joined
	,0 AS is_ag_joined
	,0 AS is_ag_primary
	,0 AS is_ag_secondary
FROM sys.databases
 

DECLARE @db_name sysname, @final_query nvarchar(2000);
 
DECLARE crsr CURSOR LOCAL FAST_FORWARD FOR
	SELECT [name] FROM #choose_db_table
	WHERE is_user_db + @include_system_db >= 1 AND is_bulk + is_full + @include_simple_rec >= 1
	AND is_simple + is_full + @include_bulk_rec >= 1 AND is_simple + is_bulk + @include_full_rec >= 1
	AND is_restricted_user + is_multi_user + @include_single_user >= 1 AND is_single_user + is_multi_user + @include_restricted_user >= 1
	AND is_single_user + is_restricted_user + @include_multi_user >= 1 AND is_online + @include_emergency >= 1
	AND is_not_contained + @include_contained >= 1 AND is_ag_joined + @include_not_ag >= 1
	AND is_not_ag_joined + @include_ag >= 1 AND is_ag_secondary + @include_ag_primary >= 1
	AND is_ag_primary + @include_ag_secondary >= 1 AND [name] Like '%'+@db_name_pattern+'%'
	AND is_offline <> 1 AND is_restoring <> 1
 
OPEN crsr;
	FETCH NEXT FROM crsr INTO @db_name
	WHILE @@FETCH_STATUS = 0
	BEGIN
	SET @final_query = 'USE ['+@db_name+'] '+CHAR(13)+@query
/*INCLUDE CHANGES OF A DEFINITION OF RESULTS TABLE*/
	exec (@final_query);
	FETCH NEXT FROM crsr INTO @db_name
END
CLOSE crsr;
DEALLOCATE crsr;
 
/*GET ALL RESULTS FOR SELECT QUERIES*/
 
IF OBJECT_ID('#user_results_table') IS NOT NULL BEGIN
SELECT *
FROM #user_results_table
END
 
/*LIST DATABASE EXCLUDED FROM THE QUERY*/
 
SELECT
	[name] AS db_excluded
	,DATABASEPROPERTYEX([name],'Status') AS [status]
	,DATABASEPROPERTYEX([name],'user_access') AS user_access
	,DATABASEPROPERTYEX([name],'Updateability') AS updateability
FROM #choose_db_table
WHERE is_user_db + @include_system_db < 1 OR is_bulk + is_full + @include_simple_rec < 1
	OR is_simple + is_full + @include_bulk_rec < 1 OR is_simple + is_bulk + @include_full_rec < 1
	OR is_restricted_user + is_multi_user + @include_single_user < 1 OR is_single_user + is_multi_user + @include_restricted_user < 1
	OR is_single_user + is_restricted_user + @include_multi_user < 1 OR is_online + @include_emergency < 1
	OR is_not_contained + @include_contained < 1 OR is_ag_joined + @include_not_ag < 1
	OR is_not_ag_joined + @include_ag < 1 OR is_ag_secondary + @include_ag_primary < 1
	OR is_ag_primary + @include_ag_secondary < 1 OR [name] NOT Like '%'+@db_name_pattern+'%'
	OR is_offline = 1 OR is_restoring = 1;
 
DROP TABLE #choose_db_table;
DROP TABLE #user_results_table;
