SET NOCOUNT ON;
 
SELECT
	bs.[database_name] AS [database_name]
	--,CAST(ROUND(bs.backup_size * 1.0 / (1024*1024*1024), 2) AS NUMERIC(10, 2)) AS total_size_mb
	,CAST(ROUND(bs.compressed_backup_size * 1.0 / (1024*1024*1024), 2) AS numeric(10, 2)) AS compressed_size_gb
	,bs.[user_name] AS backup_by_username
	,CASE bs.[type]
		WHEN 'D' THEN 'Full'
		WHEN 'I' THEN 'Diff'
		WHEN 'L' THEN 'Log'
	END AS backup_type
	,bs.recovery_model AS recovery_model
	--,bs.[compatibility_level]
	,CONVERT(varchar(20), bs.backup_finish_date, 13) AS backup_completed
	--,CAST(bmf.physical_device_name AS varchar(200)) AS physical_device_name
	--,DATEDIFF(minute, bs.backup_start_date, bs.backup_finish_date) AS duration_min
	/*
	,CASE
		WHEN LEFT(bmf.physical_device_name, 1) = '{' THEN 'SQL VSS Writer'
		WHEN LEFT(bmf.physical_device_name, 3) LIKE '[A-Za-z]:\%' THEN 'SQL Backup'
		WHEN LEFT(bmf.physical_device_name, 2) LIKE '\\' THEN 'SQL Backup'
		ELSE bmf.physical_device_name
	END AS backup_tool
	*/
	,bs.is_copy_only
	,bs.is_password_protected
	,bs.has_backup_checksums
	--,bs.is_force_offline /* for WITH NORECOVERY option */
FROM msdb.dbo.backupset AS bs
INNER JOIN msdb.dbo.backupmediafamily AS bmf ON bs.media_set_id = bmf.media_set_id
WHERE 1=1
	AND bs.[database_name] = DB_NAME() -- remove this condition if you want all DBs
	AND bs.backup_finish_date > DATEADD(MONTH, -1, GETDATE()) -- Get data for past 1 month
	AND bs.is_copy_only = 0
ORDER BY bs.backup_finish_date DESC;
