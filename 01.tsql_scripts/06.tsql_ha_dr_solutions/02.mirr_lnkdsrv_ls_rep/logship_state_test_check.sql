/*
Created by: Mateusz Wierzbowski
Creation date: 2021/08/06
Aim: Get an overview of last log restore for all user DBs
*/
USE tempdb;
SET NOCOUNT ON;
 
WITH restore_overview_cte AS (
SELECT
	rh.destination_database_name
	,rh.restore_date
	,rh.restore_type
	,ROW_NUMBER() OVER (PARTITION BY rh.destination_database_name ORDER BY rh.restore_date DESC) AS row_no
FROM msdb.dbo.restorehistory AS rh
--Filter: only log backups applied, restores within last 2 weeks
WHERE rh.restore_type = 'L' AND rh.restore_date > GETDATE()-14
)
SELECT
	GETDATE() AS check_date
	,sdb.[name] AS [db_name]
	--If no restore was done, choose the beginning of the first year when Great Britain was using Gregorian Calendar
	,ISNULL(roc.restore_date,'1753-01-01') AS restore_date
	,CAST(DATEDIFF(mi,ISNULL(roc.restore_date,CAST('1753-01-01' AS datetime2)),GETDATE())/60.0 AS DECIMAL(10,2)) AS hours_from_restore
FROM sys.databases AS sdb
LEFT JOIN restore_overview_cte AS roc ON sdb.[name] = roc.destination_database_name
WHERE sdb.database_id > 4 AND (roc.row_no IS NULL OR roc.row_no = 1)
--Sort to have the databases with the longest period of no restores in top
ORDER BY hours_from_restore DESC;
