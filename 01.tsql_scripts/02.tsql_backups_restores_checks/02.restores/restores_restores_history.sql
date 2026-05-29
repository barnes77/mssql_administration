SET NOCOUNT ON;
 
SELECT
	bs.server_name AS source_instance
	,bs.[database_name] AS source_database
	,bs.backup_finish_date AS source_backup_date
	--,bmf.physical_device_name AS source_backup_file
	,rh.destination_database_name AS target_database
	,rh.restore_date AS restore_date
	,CASE
		WHEN rh.restore_type = 'D' THEN 'Full'
		WHEN rh.restore_type = 'I' THEN 'Diff'
		WHEN rh.restore_type = 'L' THEN 'Log'
		ELSE 'Other'
	END AS restore_type
	--,rh.replace,rh.recovery,rh.stop_at,rh.stop_before --restore options
	--,rf.destination_phys_drive AS target_file_drive, rf.destination_phys_name AS target_file_name --restored data and log files
FROM msdb.dbo.restorehistory AS rh
INNER JOIN msdb.dbo.backupset AS bs ON rh.backup_set_id = bs.backup_set_id
INNER JOIN msdb.dbo.backupmediafamily AS bmf ON bs.media_set_id = bmf.media_set_id
--INNER JOIN msdb.dbo.restorefile AS rf ON rh.restore_history_id = rf.restore_history_id
--Include this condition to get restores only for certain number of days
WHERE 1=1
	AND rh.restore_date > GETDATE()-30 
	--AND bs.database_name = 'dbname_here'
ORDER BY rh.restore_date DESC;
