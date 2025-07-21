/*
Created by: Mateusz Wierzbowski
Creation date: 2019/11/12
Modification date: 2022/04/06
Aim: Get a short list of SQL jobs with basic information
Compatibility: SQL2008+
*/
SET NOCOUNT ON;
 
;WITH last_runs_cte AS (
	SELECT 
		job_id
		,run_status
		,msdb.dbo.agent_datetime(run_date,run_time) AS last_run
		,[message]
		,ROW_NUMBER() OVER (PARTITION BY job_id ORDER BY msdb.dbo.agent_datetime(run_date,run_time) DESC) AS row_no
	FROM msdb.dbo.sysjobhistory
	WHERE step_id = 0
)
 
SELECT
	sj.[name]
	,CASE sj.[enabled]
		WHEN 1 THEN 'enabled'
		ELSE 'disabled'
		END AS [status]
	,spri.[name] AS job_owner
	,lc.last_run
	,CASE lc.run_status
		WHEN 0 THEN 'Failed'
		WHEN 1 THEN 'Succeeded'
		WHEN 2 THEN 'Retry'
		WHEN 3 THEN 'Canceled'
		WHEN 4 THEN 'IN progress'
	END AS last_result
	,sj.date_created
	,msdb.dbo.agent_datetime(sjs.next_run_date,sjs.next_run_time) AS next_run
	,sj.date_modified
	,lc.[message] AS last_run_log
FROM msdb.dbo.sysjobs AS sj
LEFT JOIN msdb.dbo.sysjobschedules AS sjs ON sj.job_id = sjs.job_id
LEFT JOIN last_runs_cte AS lc ON sj.job_id = lc.job_id
LEFT JOIN sys.server_principals AS spri ON sj.owner_sid = spri.sid
WHERE row_no = 1
ORDER BY [name] ;
