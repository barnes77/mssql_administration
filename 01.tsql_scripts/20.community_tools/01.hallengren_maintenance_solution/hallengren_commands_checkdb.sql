SET NOCOUNT ON;
 
SELECT
	DatabaseName AS [database_name]
	,CONVERT(char(19),StartTime,20) AS start_time
	,DATEDIFF(ss,StartTime,EndTime) AS execution_time_ss
	,DATEDIFF(mi,StartTime,EndTime) AS execution_time_min
	,AVG(DATEDIFF(ss,StartTime,EndTime)) OVER (PARTITION BY DatabaseName)  AS avg_execution_time_ss
	,AVG(DATEDIFF(mi,StartTime,EndTime)) OVER (PARTITION BY DatabaseName)  AS avg_execution_time_min
	,ErrorNumber,ErrorMessage
FROM dbo.CommandLog
WHERE 1=1 
	AND CommandType = 'DBCC_CHECKDB'
--	AND DatabaseName LIKE '%%'
--	AND DatabaseName = ''
	AND DATEDIFF(dd,StartTime,GETDATE()) < 30
--	AND ErrorNumber <> 0
ORDER BY start_time DESC;
