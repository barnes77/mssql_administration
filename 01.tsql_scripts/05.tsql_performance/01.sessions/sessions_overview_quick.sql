--check runtime, session_id from sysprocesses and active transactions
SET NOCOUNT ON;
 
SELECT
		GETDATE() AS runtime
		,dm_tasdt.session_id
		,sproc.open_tran
		,dm_tasdt.is_snapshot
		,sproc.last_batch
		,sproc.kpid
		,sproc.blocked
		,sproc.lastwaittype
		,sproc.waitresource
		,DB_NAME(sproc.[dbid]) AS [database_name]
		,sproc.physical_io
		,sproc.[status]
		,sproc.hostname
		,sproc.[program_name]
		,sproc.cmd
		,sproc.loginame
FROM sys.dm_tran_active_snapshot_database_transactions AS dm_tasdt
INNER JOIN sys.sysprocesses AS sproc ON dm_tasdt.session_id = sproc.spid
ORDER BY sproc.open_tran DESC;
