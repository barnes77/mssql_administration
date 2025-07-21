/*
Created by: Mateusz Wierzbowski
Creation date: 2024/07/10
Aim: Get total size of growth and shrink events per database, date and event type
*/
SET NOCOUNT ON;
 
DECLARE @path NVARCHAR(260);
 
SELECT
	@path = REVERSE(SUBSTRING(REVERSE([path]),CHARINDEX('\', REVERSE([path])), 260)) + N'log.trc'
FROM sys.traces
WHERE is_default = 1;
 
;WITH my_temp_cte AS ( 
	SELECT
		CASE
			WHEN EventClass IN (92, 93, 94, 95) THEN DatabaseName
			WHEN EventClass = 116 AND TextData NOT LIKE '%@%' THEN (SELECT
				sdb.[name]
				FROM sys.master_files AS mf
				JOIN sys.databases AS sdb ON sdb.database_id = mf.database_id
				WHERE mf.[name] = REPLACE(REPLACE(CAST(TextData AS nvarchar(1000)),'DBCC SHRINKFILE (',''),')','') )
			WHEN EventClass = 116 AND TextData LIKE '%@%' THEN (SELECT
				sdb.[name]
				FROM sys.master_files AS mf
				JOIN sys.databases AS sdb ON sdb.database_id = mf.database_id
				WHERE mf.[name] = LEFT(REPLACE(CAST(TextData AS nvarchar(1000)),'DBCC SHRINKFILE (',''),CHARINDEX('@',REPLACE(CAST(TextData AS nvarchar(1000)),'DBCC SHRINKFILE (',''))-1) )
		END AS [database_name]
		,CASE
			WHEN EventClass IN (92, 93, 94, 95) THEN [FileName]
			WHEN EventClass = 116 AND TextData NOT LIKE '%@%' THEN REPLACE(REPLACE(CAST(TextData AS nvarchar(1000)),'DBCC SHRINKFILE (',''),')','')
			WHEN EventClass = 116 AND TextData LIKE '%@%' THEN LEFT(REPLACE(CAST(TextData AS nvarchar(1000)),'DBCC SHRINKFILE (',''),CHARINDEX('@',REPLACE(CAST(TextData AS nvarchar(1000)),'DBCC SHRINKFILE (',''))-1)
		END AS [file_name]
		,CASE
			WHEN EventClass = 92 THEN 'AutoGrowth_Data'
			WHEN EventClass = 93 THEN 'AutoGrowth_Log'
			WHEN EventClass = 94 THEN 'AutoShrink_Data'
			WHEN EventClass = 95 THEN 'AutoShrink_Log'
			WHEN EventClass = 116 AND TextData LIKE '%shrink%' THEN 'ManualShrink'
		END AS [event]
		,CAST(IntegerData/128.0 AS decimal(10,2)) AS size_change_mb
		,LoginName AS [login_name]
		,SPID AS spid
		,StartTime AS start_time
		,EndTime AS end_time
		,CAST(StartTime AS date) AS [date]
		,DATEDIFF(ss,StartTime,EndTime) AS [duration]
	FROM sys.fn_trace_gettable(@path, DEFAULT)
	WHERE 1=0
		OR EventClass IN (92,93,94,95) 
		OR (EventClass IN (116) AND TextData LIKE '%shrink%'))
SELECT 
	[date]
	,[database_name]
	,file_name
	,[event]
	,spid
	,SUM(size_change_mb) AS size_change_total_mb
	,SUM(duration) AS duration_ss
	,COUNT(start_time) AS occurrences_no
FROM my_temp_cte
WHERE 1=1
	AND [database_name] IS NOT NULL
	--AND [database_name] LIKE '%%'
	--AND [event] IN ('AutoGrowth_Data','AutoGrowth_Log') --autogrowth events only
	AND [event] IN ('AutoGrowth_Log','AutoShrink_Log','ManualShrink') --log's growths and shrinks events only
GROUP BY [date],[database_name],file_name,[event],spid
ORDER BY [date] DESC,[database_name] ASC;
