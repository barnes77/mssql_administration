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
Run full backup of the database manually
Change the recovery model to simple */
USE [master]
ALTER DATABASE [YourDatabase] SET RECOVERY SIMPLE WITH NO_WAIT
 
/* Shrink the log afterwards */
USE [YourDatabase]
DBCC SHRINKFILE (YourDatabaseLog,0);
 
/* Verify that there are only default VLFs in the log, i.e. if all VLFs have CreateLSN = 0 */
DBCC LOGINFO ('YourDatabase');
 
/* Change the recovery model to full */
USE [master]
ALTER DATABASE [YourDatabase] SET RECOVERY FULL WITH NO_WAIT;
/* Rebuild the log - set it to a reasonable size, e.g. the size from before the repair
or 2000 MB for growth 100 MB, 4000 MB for growth 250 MB or 8000 MB for growth 500 MB */
 
/* Run full backup of the database manually */
