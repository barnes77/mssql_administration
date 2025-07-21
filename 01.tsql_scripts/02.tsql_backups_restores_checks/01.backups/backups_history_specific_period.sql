/*
Created by Mateusz Wierzbowski
Creation date: 2019/01/29
Aim: List all backups performed for all DBs for specific period
*/
SET NOCOUNT ON;
 
SELECT
	bs.[database_name] AS [database_name]
	,bms.[name] AS backup_tool
	,bs.[user_name] AS backup_taken_by
	,CASE bs.[type]	
		WHEN 'L' THEN 'log'
		WHEN 'D' THEN 'full'
		WHEN 'F' THEN 'file'
		WHEN 'I' THEN 'diff'
		WHEN 'G' THEN 'diff_file'
		WHEN 'P' THEN 'partial'
		WHEN 'Q' THEN 'diff_partial'
		ELSE NULL
	END AS backup_type
	,CONVERT(CHAR(16),bs.backup_start_date,20) AS backup_start
	,CONVERT(CHAR(16),bs.backup_finish_date,20) AS backup_finish
FROM msdb.dbo.backupmediafamily AS bmf
INNER JOIN msdb.dbo.backupmediaset AS bms ON bmf.media_set_id = bms.media_set_id
INNER JOIN msdb.dbo.backupset AS bs ON bs.media_set_id = bms.media_set_id
WHERE bs.backup_finish_date BETWEEN '2018-09-30' AND '2019-01-01' --Dates in YYYY-MM-DD format
ORDER BY backup_start DESC;
