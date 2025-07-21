/*
Created by: Mateusz Wierzbowski
Creation date: 2019/11/06
Aim: List all database files on the SQL instance
*/
USE tempdb;
SET NOCOUNT ON;
 
IF OBJECT_ID('#dba_file_info','U') IS NOT NULL BEGIN DROP TABLE #dba_file_info; END
 
CREATE TABLE #dba_file_info (
	[database_name] nvarchar(400)
	,[name] nvarchar(100)
	,physical_name nvarchar(1000)
	,growth nvarchar(1000)
	,size_mb decimal(20,2)
	,free_space_mb decimal(20,2)
);
 
INSERT #dba_file_info
exec sp_MSforeachdb 'USE [?]
	SELECT
		sd.[name] AS [database_name]
		,sdf.[name]
		,sdf.physical_name
		,CASE
			WHEN sdf.growth = 0 THEN ''0''
			WHEN sdf.is_percent_growth = 1 THEN CAST(CAST(sdf.growth AS DECIMAL (20,2)) AS nvarchar(500))+ '' %''
			WHEN sdf.is_percent_growth = 0 THEN CAST(CAST((sdf.growth*8/1024.0) AS DECIMAL(20,2)) AS nvarchar(500))+ '' MB''
		END AS growth
		,(sdf.size*1.0/128) AS size_mb
		,(sdf.size*1.0/128)-(FILEPROPERTY(sdf.[name], ''SpaceUsed'')*1.0/128) AS free_space_mb
	FROM sys.database_files AS sdf
	JOIN sys.master_files AS smf ON smf.[name] COLLATE Latin1_General_CI_AS_KS_WS = sdf.[name] COLLATE Latin1_General_CI_AS_KS_WS
	JOIN sys.databases AS sd ON smf.database_id = sd.database_id';
 
SELECT
	[database_name]
	,[name]
	,physical_name
	,growth
	,size_mb
	,free_space_mb
FROM #dba_file_info;
 
DROP TABLE #dba_file_info;
