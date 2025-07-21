USE tempdb;
SET NOCOUNT ON;
 
DECLARE @archive INT;
 
IF OBJECT_ID('#dba_enum_error_logs','U') IS NOT NULL BEGIN DROP TABLE #dba_enum_error_logs; END
IF OBJECT_ID('#dba_read_error_log','U') IS NOT NULL BEGIN DROP TABLE #dba_read_error_log; END
 
CREATE TABLE #dba_enum_error_logs (	
	[archive] int,
	[date] datetime,
	log_file_size_byte int
);
CREATE TABLE #dba_read_error_log (	
	log_date datetime,
	process_info varchar(50),
	[text] varchar(4000)
);
 
INSERT INTO #dba_enum_error_logs
	exec [sys].[xp_enumerrorlogs];
 
DECLARE cur_enumerrorlogs CURSOR FOR SELECT [archive] FROM #dba_enum_error_logs ORDER BY [archive] DESC;
OPEN cur_enumerrorlogs;
FETCH NEXT FROM cur_enumerrorlogs INTO @archive;
 
WHILE @@FETCH_STATUS = 0
BEGIN
	INSERT INTO #dba_read_error_log exec sys.xp_readerrorlog @archive;
	FETCH NEXT FROM cur_enumerrorlogs INTO @archive;
END
 
CLOSE cur_enumerrorlogs;
DEALLOCATE cur_enumerrorlogs;
 
-- optional below "login"
SELECT * FROM #dba_read_error_log
WHERE 1=1 
	AND LOWER([text]) LIKE '%login%failed%'
--	AND LOWER([text]) LIKE '%loginname%'
--	AND LOWER([text]) LIKE '%errormessage%'
ORDER BY log_date DESC;
 
DROP TABLE #dba_read_error_log;
DROP TABLE #dba_enum_error_logs;
