--Look for suspect_pages
SELECT
	DB_NAME(database_id) AS [database_name]
	,[file_id]
	,page_id
	,event_type
	,error_count
	,last_update_date
FROM msdb.dbo.suspect_pages;
 
--Look for damaged backups
SELECT
	[database_name]
	,backup_start_date
	,backup_finish_date
	,is_damaged
FROM msdb.dbo.backupset
WHERE is_damaged = 1
ORDER BY backup_start_date DESC;
