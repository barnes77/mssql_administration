SET NOCOUNT ON;
 
SELECT
	dm_er.session_id
	,dm_er.status
	,dm_er.command
	,dm_er.start_time
	,dm_er.blocking_session_id
	,CONVERT(numeric(6,2),dm_er.percent_complete) AS percent_complete
	,CONVERT(varchar(20),DATEADD(ms,dm_er.estimated_completion_time,GETDATE()),20) AS eta_completion_time
	,CONVERT(numeric(10,2),dm_er.total_elapsed_time/1000.0/60.0) AS elapsed_min
	,CONVERT(numeric(10,2),dm_er.estimated_completion_time/1000.0/60.0) AS eta_min
	,CONVERT(numeric(10,2),dm_er.estimated_completion_time/1000.0/60.0/60.0) AS eta_hours
	,CONVERT(varchar(1000)
	,(SELECT
		SUBSTRING([text]
		,dm_er.statement_start_offset/2
		,CASE
			WHEN dm_er.statement_end_offset = -1 THEN 1000
			ELSE (dm_er.statement_end_offset-dm_er.statement_start_offset)/2 END)
	FROM sys.dm_exec_sql_text([sql_handle]))) AS sql_statement
FROM sys.dm_exec_requests AS dm_er
WHERE command IN ('RESTORE HEADERONLY','RESTORE DATABASE','BACKUP DATABASE','RESTORE LOG','BACKUP LOG','DbccFilesCompact',
'DbccLOBCompact','DbccSpaceReclaim','CREATE INDEX','ALTER INDEX','KILLED/ROLLBACK ','ROLLBACK TRANSACTION',
'DBCC','DBCC TABLE CHECK','DBCC ALLOC CHECK','DBCC SYS CHECK','DBCC SSB CHECK','DBCC CHECKCATALOG','DBCC IVIEW CHECK',
'DBCC TABLE REPAIR','DBCC ALLOC REPAIR','DBCC SYS REPAIR');
