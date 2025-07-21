SET NOCOUNT ON;
 
SELECT
	lss.primary_server AS primary_server
	,lss.primary_database
	,@@SERVERNAME AS secondary_server
	,lssd.secondary_database
	,lss.monitor_server
	,lss.backup_source_directory
	,lss.backup_destination_directory
	,CAST(lss.file_retention_period/60 AS nvarchar(100))+' hrs' AS backup_retention
	,sj1.[name] AS copy_job
	,CASE WHEN sj1.[enabled] = 1 THEN 'Enabled' ELSE 'Disabled' END AS copy_job_status
	--,lss.last_copied_date
	--,lss.last_copied_file
	,sj2.[name] AS restore_job
	,CASE WHEN sj2.[enabled] = 1 THEN 'Enabled' ELSE 'Disabled' END AS restore_job_status
	--,lssd.last_restored_date
	--,lssd.last_restored_file
FROM msdb.dbo.log_shipping_secondary AS lss
LEFT JOIN msdb.dbo.log_shipping_secondary_databases AS lssd ON lss.secondary_id = lssd.secondary_id
LEFT JOIN msdb.dbo.sysjobs AS sj1 ON lss.copy_job_id = sj1.job_id
LEFT JOIN msdb.dbo.sysjobs AS sj2 ON lss.restore_job_id = sj2.job_id;
