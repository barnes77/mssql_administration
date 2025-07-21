/* Look for suspect_pages */
SELECT
	DB_NAME(database_id)
	,[file_id]
	,page_id
	,event_type
	,error_count
	,last_update_date
FROM msdb.dbo.suspect_pages;
 
/* Look for damaged backups */
SELECT
	[database_name]
	,backup_start_date
	,backup_finish_date
	,is_damaged
FROM msdb.dbo.backupset
WHERE is_damaged = 1
ORDER BY backup_start_date DESC;
 
/* Ask customer to stop the application
Alternatively disable on SQL server logins accessing the database
Run diff backup of the database manually, to be able to rollback the actions afterwards
Run checkpoint on the database */
USE [YourDatabase]
CHECKPOINT;
 
/* Execute manually log backup with continue_after_error option (this can be done via advanced options in CV as well) and shrink the log afterwards
Repeat the steps until the log is shrunk to 0 MB preferably
This is done in order to shrink the log past the corruption point */
BACKUP LOG YourDatabase TO DISK = '\\filepath\yourdatabase_yyyyMMdd_hhmmss_log.bak' WITH CONTINUE_AFTER_ERROR;
USE [YourDatabase]
DBCC SHRINKFILE (YourDatabaseLog,0);
 
/* Verify that there are only default VLFs in the log, i.e. if all VLFs have CreateLSN = 0 */
DBCC LOGINFO ('YourDatabase');
 
/* If the log is shrunk completely, run the standard log backup job or standard log backup from CV */
 
/* If the log backup job completes successfully, rebuild the log - set it to a reasonable size, e.g. the size from before the repair
/* or 2000 MB for growth 100 MB, 4000 MB for growth 250 MB or 8000 MB for growth 500 MB */
