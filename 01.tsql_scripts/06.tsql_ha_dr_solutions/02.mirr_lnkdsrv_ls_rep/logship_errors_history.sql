SET NOCOUNT ON;
 
SELECT TOP 100
	log_time
	,sequence_number
	,CASE
		WHEN agent_type = 0 THEN 'Backup'
		WHEN agent_type = 1 THEN 'Copy'
		ELSE 'Restore'
	END AS agent
	,[database_name]
	,source
	,[message]
FROM msdb.dbo.log_shipping_monitor_error_detail
ORDER BY log_time DESC, sequence_number DESC;
