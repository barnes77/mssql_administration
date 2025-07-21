SET NOCOUNT ON;
 
SELECT
	@@SERVERNAME AS primary_server
	,lspd.primary_database
	,lsps.secondary_server
	,lsps.secondary_database
	,lspd.monitor_server
	,lspd.backup_directory
	,lspd.backup_share
	,sj.[name] AS backup_job
	,CASE WHEN sj.[enabled] = 1 THEN 'Enabled' ELSE 'Disabled' END AS backup_job_status
	,CAST(lspd.backup_retention_period/60 AS nvarchar(100))+' hrs' AS backup_retention
	--,lspd.last_backup_date
	--,lspd.last_backup_file
FROM msdb.dbo.log_shipping_primary_databases AS lspd
LEFT JOIN msdb.dbo.log_shipping_primary_secondaries AS lsps ON lspd.primary_id = lsps.primary_id
LEFT JOIN msdb.dbo.sysjobs AS sj ON lspd.backup_job_id = sj.job_id;
