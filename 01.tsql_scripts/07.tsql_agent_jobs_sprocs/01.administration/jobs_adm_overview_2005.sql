/*
Created by: Mateusz Wierzbowski
Creation date: 2019/11/12
Aim: Get a short list of SQL jobs with basic information
Compatibility: SQL2005+
*/
SET NOCOUNT ON;
 
SELECT
	sj.[name]
	,CASE sj.[enabled]
		WHEN 1 THEN 'enabled'
		ELSE 'disabled'
		END AS [status]
	,spri.[name] AS job_owner
	,sj.date_created
	,msdb.dbo.agent_datetime(sjh.run_date,sjh.run_time) AS last_run
	,CASE sjh.run_status
		WHEN 0 THEN 'Failed'
		WHEN 1 THEN 'Succeeded'
		WHEN 2 THEN 'Retry'
		WHEN 3 THEN 'Canceled'
		WHEN 4 THEN 'IN progress'
	END AS last_result
	,msdb.dbo.agent_datetime(sjs.next_run_date,sjs.next_run_time) AS next_run
	,sj.date_modified
	,sjh.[message] AS last_run_log
FROM msdb.dbo.sysjobs AS sj
LEFT JOIN msdb.dbo.sysjobschedules AS sjs ON sj.job_id = sjs.job_id
LEFT JOIN msdb.dbo.sysjobhistory AS sjh ON sj.job_id = sjh.job_id
LEFT JOIN sys.server_principals AS spri ON sj.owner_sid = spri.sid
WHERE sjh.step_id = 0 AND msdb.dbo.agent_datetime(sjh.run_date,sjh.run_time) IN
	(SELECT MAX(msdb.dbo.agent_datetime(sjh.run_date,sjh.run_time))
	FROM msdb.dbo.sysjobhistory AS sjh
	GROUP BY sjh.job_id)
ORDER BY [name];
