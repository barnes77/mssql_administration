/*
Created by: Mateusz Wierzbowski
Creation date: 2020/10/08
Aim: Get a list of sessions with their wait types and information about memory grants
*/
SET NOCOUNT ON;
 
SELECT
	dm_er.session_id
	,dm_er.wait_type
	,dm_es.[host_name]
	,dm_es.logical_reads,dm_es.reads,dm_es.writes--,dm_es.text_size
	,dm_es.login_time
	,dm_es.[program_name]
	--,dm_eqmg.request_time,dm_eqmg.grant_time
	,dm_eqmg.requested_memory_kb,dm_eqmg.granted_memory_kb,dm_eqmg.required_memory_kb,dm_eqmg.used_memory_kb,dm_eqmg.max_used_memory_kb
	,dm_eqmg.query_cost
	,dm_eqmg.timeout_sec
	,dm_eqmg.wait_order, dm_eqmg.is_next_candidate
FROM sys.dm_exec_requests AS dm_er
LEFT JOIN sys.dm_exec_sessions AS dm_es ON dm_er.session_id = dm_es.session_id
LEFT JOIN sys.dm_exec_query_memory_grants AS dm_eqmg ON dm_er.session_id = dm_eqmg.session_id
WHERE 1=1
	AND dm_er.wait_type IS NOT NULL 
	AND dm_es.[host_name] IS NOT NULL
ORDER BY dm_er.wait_type;
