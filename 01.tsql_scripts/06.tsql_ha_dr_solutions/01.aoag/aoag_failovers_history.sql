/*
Created by: Mateusz Wierzbowski
Create date: 2020/01/28
Aim: Gather information about history of failovers
*/
SET NOCOUNT ON;
 
WITH aoag_failovers_cte AS (
	SELECT
		[object_name]
		,CONVERT(XML, event_data) AS [data]
	FROM sys.fn_xe_file_target_read_file('AlwaysOn*.xel', null, null, null)
)
 
SELECT TOP 50
	[data].value('(/event/@timestamp)[1]','datetime') AS event_date
	,[data].value('(/event/@name)[1]','nvarchar(200)') AS event_type
	,[data].value('(/event/data[@name=''availability_replica_name''])[1]','nvarchar(400)') AS [replica_name]
	,[data].value('(/event/data[@name=''availability_group_name''])[1]','nvarchar(400)') AS [ag_group]
	,[data].value('(/event/data[@name=''current_state'']/text)[1]','nvarchar(400)') AS [current_state]
FROM aoag_failovers_cte
WHERE 1=1
	AND [data].value('(/event/@name)[1]','nvarchar(200)') LIKE '%availability_replica_state_change%'
	AND [data].value('(/event/data[@name=''current_state'']/text)[1]','nvarchar(400)') IN ('PRIMARY_NORMAL','SECONDARY_NORMAL') --Remove Below Condition to get full view of changes in replica's state
ORDER BY event_date DESC;
