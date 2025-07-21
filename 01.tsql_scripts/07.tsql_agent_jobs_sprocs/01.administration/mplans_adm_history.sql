/*
Source: stackoverflow.com/questions/33858357/sql-server-maintenance-plan-history-check-for-success-or-failure
Modified by Mateusz Wierzbowski
Date of modification: 2021/02/17
Aim: Verify history of jobs being parts of Maintenance Plans
*/
SET NOCOUNT ON;
 
WITH maint_plans_cte AS (
	SELECT
		smps.[name] AS maint_plan_name
		,smsp.subplan_name AS subplan_name
		,smpl.start_time AS job_start
		,smpl.end_time AS job_end
		,smpl.succeeded AS job_succeeded
		,ROW_NUMBER() OVER (PARTITION BY smps.[name], smsp.subplan_name ORDER BY smpl.start_time DESC) AS row_no
	FROM msdb.dbo.sysmaintplan_plans AS smps
	INNER JOIN msdb.dbo.sysmaintplan_subplans AS smsp ON smps.id = smsp.plan_id
	INNER JOIN msdb.dbo.sysmaintplan_log AS smpl ON smsp.subplan_id = smpl.subplan_id
	/*AND smpl.task_detail_id = (SELECT TOP 1 ld.task_detail_id FROM msdb.dbo.sysmaintplan_logdetail ld
			WHERE ld.command LIKE ('%['+db_name()+']%') --Place db_name here to limit the history of MaintenancePlans
			ORDER BY ld.start_time DESC)*/
)
SELECT
	maint_plan_name
	,subplan_name
	,job_start
	,job_end
	,job_succeeded
FROM maint_plans_cte 
WHERE row_no <= 10; -- Limit history here
