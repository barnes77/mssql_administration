--Run against DB using CDC
SET NOCOUNT ON;
 
SELECT TOP 10
	[session_id]
	,entry_time
	,[error_number]
	,[error_message]
	,start_lsn
	,begin_lsn
	,sequence_value
FROM sys.dm_cdc_errors
ORDER BY entry_time DESC;
 
SELECT TOP 10
	[session_id]
	,start_time
	,end_time
	,duration
	,scan_phase
	,error_count
	,start_lsn
	,current_lsn
	,end_lsn
	,tran_count
	,last_commit_lsn
	,last_commit_time
	,log_record_count
	,schema_change_count
	,command_count
	,first_begin_cdc_lsn
	,last_commit_cdc_lsn
	,last_commit_cdc_time
	,latency
	,empty_scan_count
	,failed_sessions_count
FROM sys.dm_cdc_log_scan_sessions
WHERE error_count > 0
ORDER BY start_time ASC;
