/*
Created by: Mateusz Wierzbowski
Creation date: 2022/04/19
Aim: Gather information about last 100 executions
*/
USE ReportServer;
SET NOCOUNT ON;
 
SELECT TOP 100
	c.[Name] AS [report_name]
	,el.[UserName] AS [user_name]
	,el.[Format] AS [format]
	,el.TimeStart AS [time_start]
	--,el.ReportID AS [report_id]
	--,c.[Path] AS [report_path]
	--,el.[Parameters] AS [parameters]
	,el.TimeProcessing/1000 AS [time_processing_secs]
	,el.TimeRendering/1000 AS [time_rendering_secs]
	,(el.TimeProcessing + el.TimeRendering)/1000  AS [total_time_secs]
	,el.[Source] AS [source]
	,CAST(el.ByteCount/(1024*1024.00) AS DECIMAL(10,2)) AS [data_size_mb]
	,el.[RowCount] AS [row_count]
	,el.[Status] AS [status]
FROM dbo.ExecutionLog AS el
LEFT JOIN dbo.[Catalog] AS c ON el.ReportID = c.ItemID
WHERE 1=1
--	AND c.[Name] LIKE '%%'
--	AND el.TimeStart < '2022-03-18 00:00:00.001'
--	AND el.[Parameters] LIKE '%database_name%'
--	AND el.[Status] = 'rsHttpRuntimeClientDisconnectionError'
--	AND el.[Status] <> 'rsSuccess'
/*Ordering*/
ORDER BY el.TimeStart DESC;
--ORDER BY el.TimeStart ASC;
--ORDER BY el.[RowCount] DESC;
--ORDER BY el.ByteCount DESC;
--ORDER BY el.TimeProcessing DESC;
--ORDER BY el.TimeRendering DESC;
--ORDER BY (el.TimeProcessing + el.TimeRendering) DESC;
