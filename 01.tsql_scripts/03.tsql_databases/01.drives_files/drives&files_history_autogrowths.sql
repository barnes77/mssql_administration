SET NOCOUNT ON;
DECLARE @path nvarchar(260);
 
SELECT @path = REVERSE(SUBSTRING(REVERSE([path]),CHARINDEX('\', REVERSE([path])), 260)) + N'log.trc'
FROM sys.traces
WHERE is_default = 1;
 
SELECT
	DatabaseName AS [database_name]
	,[FileName] AS [file_name]
	,SPID AS spid
	,Duration AS duration
	,StartTime AS start_time
	,EndTime AS end_time
	,CASE EventClass
		 WHEN 92 THEN 'Data'
		 WHEN 93 THEN 'Log'
	END AS file_type
FROM sys.fn_trace_gettable(@path, DEFAULT)
WHERE EventClass IN (92,93)
ORDER BY start_time DESC;
