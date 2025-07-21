/*
Created by: Mateusz Wierzbowski
Creation date: 2021/07/27
Aim: Get info about drives_cte, their space and type of usage
*/
USE tempdb;
SET NOCOUNT ON;
 
WITH drives_cte AS (
	SELECT DISTINCT
		volume_mount_point AS [name]
		,CAST(total_bytes*1.0/(1024*1024*1024) AS decimal(20,2)) AS total_space
		,CAST(available_bytes*1.0/(1024*1024*1024) AS decimal(20,2)) AS free_space_gb
		,CAST((available_bytes*1.0/(1024*1024*1024))/(total_bytes*1.0/(1024*1024*1024))*100 AS decimal(20,2)) AS free_space_perc
	FROM sys.master_files AS smf
	CROSS APPLY sys.dm_os_volume_stats(smf.database_id, smf.file_id)
), files_cte AS (
	SELECT
		physical_name
		,database_id
		,[type]
		,CASE
			WHEN database_id < 5 AND database_id <> 2 THEN 2
			WHEN database_id = 2 THEN 4
			ELSE 8
		END AS db_type
	FROM sys.master_files
)
 
SELECT
	dc.[name]
	,dc.total_space
	,dc.free_space_gb
	,dc.free_space_perc
	,CASE
		WHEN MIN(fc.type) = 0 AND MAX(fc.type) = 0 THEN 'data'
		WHEN MIN(fc.type) = 0 AND MAX(fc.type) = 1 THEN 'data & logs'
		WHEN MIN(fc.type) = 1 AND MAX(fc.type) = 1 THEN 'logs'
	END AS [db_files_type]
	,CONCAT(
		CASE WHEN MAX(fc.db_type & 2) = 2 THEN 'systemDBs' END
		,CASE WHEN MAX(fc.db_type & 2) = 2 AND (MAX(fc.db_type & 4) = 4 OR MAX(fc.db_type & 8) = 8) THEN ', ' END
		,CASE WHEN MAX(fc.db_type & 4) = 4 THEN 'tempDB' END
		,CASE WHEN MAX(fc.db_type & 4) = 4 AND MAX(fc.db_type & 8) = 8 THEN ', ' END
		,CASE WHEN MAX(fc.db_type & 8) = 8 THEN 'userDBs' END ) AS db_type
FROM drives_cte AS dc
LEFT JOIN files_cte AS fc ON dc.[name] = LEFT(fc.physical_name,LEN(dc.[name]))
GROUP BY dc.[name], dc.total_space, dc.free_space_gb, dc.free_space_perc
ORDER BY dc.[name];
