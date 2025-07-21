--script from A182300
SET NOCOUNT ON;
 
SELECT
	dm_tst.session_id
	,dm_es.login_name AS login_name
	,DB_NAME (dm_tdt.database_id) AS [database_name]
	,dm_tdt.database_transaction_begin_time AS begin_time
	,dm_tdt.database_transaction_log_record_count AS log_records
	,dm_tdt.database_transaction_log_bytes_used AS log_bytes_used
	,dm_tdt.database_transaction_log_bytes_reserved AS log_bytes_reserved
	,SUBSTRING(dm_est.text, (dm_er.statement_start_offset/2)+1,((CASE dm_er.statement_end_offset
		WHEN -1 THEN DATALENGTH(dm_est.text)
		ELSE dm_er.statement_end_offset
		END - dm_er.statement_start_offset)/2) + 1) AS statement_text
	,dm_est.text AS last_tsql_text
	,dm_eqp.query_plan AS last_plan
FROM sys.dm_tran_database_transactions AS dm_tdt
JOIN sys.dm_tran_session_transactions AS dm_tst ON dm_tst.transaction_id = dm_tdt.transaction_id
JOIN sys.dm_exec_sessions AS dm_es ON dm_es.session_id = dm_tst.session_id
JOIN sys.dm_exec_connections AS dm_ec ON dm_ec.session_id = dm_tst.session_id
LEFT OUTER JOIN sys.dm_exec_requests AS dm_er ON dm_er.session_id = dm_tst.session_id
CROSS APPLY sys.dm_exec_sql_text (dm_ec.most_recent_sql_handle) AS dm_est
OUTER APPLY sys.dm_exec_query_plan (dm_er.plan_handle) AS dm_eqp
WHERE DB_NAME (dm_tdt.database_id) = 'tempdb'
ORDER BY log_bytes_used DESC;
