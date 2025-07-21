SET NOCOUNT ON;
 
DECLARE @path NVARCHAR(260);
SELECT
    @path = REVERSE(SUBSTRING(REVERSE([path]),CHARINDEX('\', REVERSE([path])), 260)) + N'log.trc'
FROM sys.traces
WHERE is_default = 1;

SELECT TOP 10
    StartTime
    ,LoginName
    ,TextData
    ,HostName
FROM sys.fn_trace_gettable(@path, DEFAULT)
WHERE 1=1 
--AND StartTime between '2023-07-26 00:00:01' and '2023-07-26 23:59:59'
AND TextData like '%phrase%'
ORDER BY StartTime DESC;
