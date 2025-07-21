USE tempdb;
SET NOCOUNT ON;
 
DECLARE @archive int;
 
IF OBJECT_ID('#dba_enum_error_logs','U') IS NOT NULL BEGIN DROP TABLE #dba_enum_error_logs; END
IF OBJECT_ID('#dba_read_error_log','U') IS NOT NULL BEGIN DROP TABLE #dba_read_error_log; END
 
CREATE TABLE #dba_enum_error_logs (
	[archive] int
	,[date] datetime
	,log_file_size_byte int
);
CREATE TABLE #dba_read_error_log (
	log_date datetime
	,process_info varchar(50)
	,[text] varchar(4000)
);
 
INSERT INTO #dba_enum_error_logs
	exec sys.xp_enumerrorlogs;
 
DECLARE cur_enumerrorlogs CURSOR FOR
	SELECT [archive] FROM #dba_enum_error_logs ORDER BY [archive] DESC;
OPEN cur_enumerrorlogs; FETCH NEXT FROM cur_enumerrorlogs INTO @archive;
WHILE @@FETCH_STATUS = 0
	BEGIN
	INSERT INTO #dba_read_error_log
		exec sys.xp_readerrorlog @archive;
	FETCH NEXT FROM cur_enumerrorlogs INTO @archive;
	END
CLOSE cur_enumerrorlogs;
DEALLOCATE cur_enumerrorlogs;
 
SELECT * FROM #dba_read_error_log
WHERE 1=1
	AND LOWER([text]) LIKE '%YourDatabase%' 
	AND (LOWER([text]) LIKE '%log%corruption%' OR (LOWER([text]) LIKE '%checkdb%errors%'
	AND LOWER([text]) NOT LIKE '%found 0 errors%' AND LOWER([text]) NOT LIKE '%without errors%'))
ORDER BY log_date ASC;
DROP TABLE #dba_read_error_log;
DROP TABLE #dba_enum_error_logs;
