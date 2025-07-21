SET NOCOUNT ON;
 
SELECT TOP 100
	log_time
	,CASE
		WHEN agent_type = 0 THEN 'Backup'
		WHEN agent_type = 1 THEN 'Copy'
		ELSE 'Restore'
	END AS agent
	,[database_name]
	,CASE
		WHEN session_status = 0 THEN 'Starting'
		WHEN session_status = 1 THEN 'Running'
		WHEN session_status = 2 THEN 'Success'
		WHEN session_status = 3 THEN 'Error'
		ELSE 'Warning'
	END AS session_status
	,[message]
FROM msdb.dbo.log_shipping_monitor_history_detail
WHERE 1=1
--	AND session_status = 3 --Uncomment this line to get errors only
--	AND session_status IN (3,4) --Uncomment this line to get errors & warnings
ORDER BY log_time DESC;
