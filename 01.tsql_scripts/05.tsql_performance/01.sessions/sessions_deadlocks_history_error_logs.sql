/*
Created by: Mateusz Wierzbowski
Creation date: 2020/11/27
Aim: Get detailed tabular report of last ten deadlocks
*/
SET NOCOUNT ON;
 
WITH deadlock_cte AS (
SELECT
	[object_name]
	,CONVERT(XML, event_data) AS [data]
FROM sys.fn_xe_file_target_read_file('system_health*.xel', null, null, null)
)
 
SELECT TOP 10
	[data].value('(/event/@timestamp)[1]','datetime') AS [timestamp]
	,[data].value('(/event/data/value/deadlock/victim-list/victimProcess/@id)[1]','nvarchar(200)') AS victim_pid
	,[data].value('(/event/data/value/deadlock/process-list/process/@id)[1]','nvarchar(200)') AS process_one_pid
	,[data].value('(/event/data/value/deadlock/process-list/process/@transactionname)[1]','nvarchar(200)') AS p_one_transcation_type
	,[data].value('(/event/data/value/deadlock/process-list/process/@spid)[1]','int') AS p_one_spid
	,[data].value('(/event/data/value/deadlock/process-list/process/@hostname)[1]','nvarchar(200)') AS p_one_hostname
	,[data].value('(/event/data/value/deadlock/process-list/process/@loginname)[1]','nvarchar(200)') AS p_one_login_name
	,[data].value('(/event/data/value/deadlock/process-list/process/@currentdb)[1]','nvarchar(200)') AS p_one_db
	,[data].value('(/event/data/value/deadlock/process-list/process/@isolationlevel)[1]','nvarchar(200)') AS p_one_iso_level
	,[data].value('(/event/data/value/deadlock/resource-list/keylock/@objectname)[1]','nvarchar(200)') AS p_one_object_locked
	,[data].value('(/event/data/value/deadlock/process-list/process/@id)[2]','nvarchar(200)') AS process_two_pid
	,[data].value('(/event/data/value/deadlock/process-list/process/@transactionname)[2]','nvarchar(200)') AS p_two_transcation_type
	,[data].value('(/event/data/value/deadlock/process-list/process/@spid)[2]','int') AS p_two_spid
	,[data].value('(/event/data/value/deadlock/process-list/process/@hostname)[2]','nvarchar(200)') AS p_two_hostname
	,[data].value('(/event/data/value/deadlock/process-list/process/@loginname)[2]','nvarchar(200)') AS p_two_login_name
	,[data].value('(/event/data/value/deadlock/process-list/process/@currentdb)[2]','nvarchar(200)') AS p_two_db
	,[data].value('(/event/data/value/deadlock/process-list/process/@isolationlevel)[2]','nvarchar(200)') AS p_two_iso_level
	,[data].value('(/event/data/value/deadlock/resource-list/keylock/@objectname)[2]','nvarchar(200)') AS p_two_object_locked
	,[data].value('(/event/data/value/deadlock/process-list/process/inputbuf)[1]','nvarchar(1000)') AS p_one_statemenet
	,[data].value('(/event/data/value/deadlock/process-list/process/inputbuf)[2]','nvarchar(1000)') AS p_two_statemenet
FROM deadlock_cte
ORDER BY [data].value('(/event/@timestamp)[1]','datetime') DESC;
