/*
Created by: Mateusz Wierzbowski
Create date: 2020/01/28
Aim: Gather information about history of AG errors
*/
SET NOCOUNT ON;
 
WITH aoag_errors_cte AS (
	SELECT
		[object_name]
		,CONVERT(XML, event_data) AS [data]
	FROM sys.fn_xe_file_target_read_file('AlwaysOn*.xel', null, null, null)
)
SELECT TOP 50
	[data].value('(/event/@timestamp)[1]','datetime') AS event_date
	,[data].value('(/event/data[@name=''error_number''])[1]','int') AS error_no
	,[data].value('(/event/data[@name=''message''])[1]','nvarchar(2000)') AS error_mess
FROM aoag_errors_cte
WHERE 1=1
	AND [data].value('(/event/@name)[1]','nvarchar(200)') LIKE '%error_reported%'
ORDER BY event_date DESC;
