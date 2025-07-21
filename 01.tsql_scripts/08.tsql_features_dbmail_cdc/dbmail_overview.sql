--Check if sysmail is started and queues
exec msdb.dbo.sysmail_help_status_sp;
exec msdb.dbo.sysmail_help_queue_sp;
 
--If not start it
--exec msdb.dbo.sysmail_start_sp;
 
--Check configuration
exec msdb.dbo.sysmail_help_configure_sp;
 
--Check profiles, related accounts
exec msdb.dbo.sysmail_help_profile_sp;
exec msdb.dbo.sysmail_help_profileaccount_sp;
exec msdb.dbo.sysmail_help_account_sp;
 
SELECT
	smp.name AS profile_name
	,smp.[description] AS profile_description
	,sma.name AS account_name
	,sma.email_address
	,sma.display_name
	,sma.replyto_address
FROM msdb.dbo.sysmail_profile AS smp
LEFT JOIN msdb.dbo.sysmail_profileaccount AS smpa ON smp.profile_id = smpa.profile_id
LEFT JOIN msdb.dbo.sysmail_account AS sma ON smpa.account_id = sma.account_id
 
--Try to restart dbmail if nothing else helps
--exec msdb.dbo.sysmail_stop_sp;
--exec msdb.dbo.sysmail_start_sp;
