/*
Source: Exam Ref 70-764 Administering a SQL Database Infrastructure
*/
SET NOCOUNT ON;
 
SELECT
	xed.value('@timestamp', 'datetime') AS deadlock_datetime
	,xed.query('.') AS deadlock_payload
FROM (
	SELECT
		CAST(target_data AS XML) AS target_data
	FROM sys.dm_xe_session_targets AS dmxst
	JOIN sys.dm_xe_sessions AS dmxs ON dmxs.address = dmxst.event_session_address
	WHERE dmxs.name = N'system_health' AND dmxst.target_name = N'ring_buffer'
	) AS XML_Data
CROSS APPLY target_data.nodes('RingBufferTarget/event[@name="xml_deadlock_report"]') AS XEventData(xed);
