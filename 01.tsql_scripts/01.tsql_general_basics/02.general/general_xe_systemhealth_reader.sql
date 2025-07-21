/*
Created by: Mateusz Wierzbowski
Create date: 2020/10/19
Aim: Get errors from XE system health
*/
SET NOCOUNT ON;
 
WITH cte_hadr AS (
SELECT 
	[object_name]
	,CONVERT(XML, event_data) AS [data]
FROM sys.fn_xe_file_target_read_file('system_health*.xel', null, null, null)
)
 
SELECT TOP 50
	data.value('(/event/@timestamp)[1]','datetime') AS event_date
	,data.value('(/event/@name)[1]','nvarchar(200)') AS event_type
	,data.value('(/event/data[@name="error_number"])[1]','int') AS [error_number]
	,data.value('(/event/data[@name="message"])[1]','nvarchar(600)') AS error_text
FROM cte_hadr
--For general errors
WHERE 1=1
	AND data.value('(/event/@name)[1]','nvarchar(200)') LIKE '%error_reported%'
--	AND data.value('(/event/@name)[1]','nvarchar(200)') LIKE '%error_reported%'
ORDER BY event_date DESC;
