SET NOCOUNT ON;
 
SELECT
    DatabaseName AS [database_name]
    ,SUM(DATEDIFF(ss,StartTime,EndTime)) AS execution_time_ss
    ,CONVERT(char(14),StartTime,23) AS execution_date
FROM dbo.CommandLog
WHERE 1=1 
    AND CommandType IN ('ALTER_INDEX','UPDATE_STATISTICS')
--  AND DatabaseName LIKE '%%'
--  AND DatabaseName = ''
    AND DATEDIFF(dd,StartTime,GETDATE()) < 30
GROUP BY CONVERT(char(14),StartTime,23),DatabaseName;
