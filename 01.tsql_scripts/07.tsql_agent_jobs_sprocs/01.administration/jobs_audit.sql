SET NOCOUNT ON;
 
;WITH job_history AS (SELECT
ROW_NUMBER() OVER (PARTITION BY sjh.job_id ORDER BY sjh.instance_id DESC) AS row_no
,sj.[name]
,sj.[job_id]
,CASE 
	WHEN sjh.run_status = 0 THEN 'Failed'
	WHEN sjh.run_status = 1 THEN 'Succeeded'
	WHEN sjh.run_status = 2 THEN 'Retry'
	WHEN sjh.run_status = 3 THEN 'Canceled'
	ELSE 'In Progress'
END AS [job_outcome]
FROM msdb.dbo.sysjobhistory AS sjh
LEFT JOIN msdb.dbo.sysjobs AS sj ON sjh.job_id = sj.job_id 
WHERE step_id = 0 AND sj.[name] IS NOT NULL)
 
SELECT
	SERVERPROPERTY('ProductVersion') AS sql_version
	,SERVERPROPERTY('Edition') AS sql_edition
	,SERVERPROPERTY('Collation') AS sql_collation
	,sj.[name] AS job_name
	,sj.[enabled] AS job_enabled
	,jh.job_outcome
	,ss.[name] AS schedule_name
	,ss.[enabled] AS schedule_enabled
	,CASE
		WHEN ss.freq_type = 1 THEN 'Single run'
		WHEN ss.freq_type = 4 THEN 'Daily'
		WHEN ss.freq_type = 8 THEN 'Weekly'
		WHEN ss.freq_type = 16 OR ss.freq_type = 32 THEN 'Monthly'
		WHEN ss.freq_type = 64 THEN 'On Agent startup'
		WHEN ss.freq_type = 128 THEN 'Computer idle'
		ELSE NULL
	END AS [schedule_type]
	,(
	CASE
		WHEN ss.freq_type = 4 THEN 'Occurs every '
		WHEN ss.freq_type = 8 THEN 'Occurs every '
		WHEN ss.freq_type = 16 THEN 'Occurs every '
		WHEN ss.freq_type = 32 THEN 'Occurs every '
		ELSE NULL
	END
	+CASE
		WHEN ss.freq_type = 4 THEN CAST(ss.freq_interval AS varchar(10))+' day(s) '
		WHEN ss.freq_type = 8 THEN CAST(ss.freq_recurrence_factor AS varchar(10))+' week(s) on '
		WHEN ss.freq_type = 16 THEN CAST(ss.freq_recurrence_factor AS varchar(10))+' month(s) on '
		WHEN ss.freq_type = 32 THEN CAST(ss.freq_recurrence_factor AS varchar(10))+' month(s) on '
		ELSE ''
	END
	+CASE
		WHEN ss.freq_type = 32 AND ss.freq_relative_interval = 1 THEN 'first '
		WHEN ss.freq_type = 32 AND ss.freq_relative_interval = 2 THEN 'second '
		WHEN ss.freq_type = 32 AND ss.freq_relative_interval = 4 THEN 'third '
		WHEN ss.freq_type = 32 AND ss.freq_relative_interval = 8 THEN 'fourth '
		WHEN ss.freq_type = 32 AND ss.freq_relative_interval = 16 THEN 'last '
		WHEN ss.freq_type = 32 AND ss.freq_relative_interval = 0 THEN ''
		ELSE ''
	END
	+CASE
		WHEN ss.freq_type = 32 AND ss.freq_interval = 1 THEN 'Sunday '
		WHEN ss.freq_type = 32 AND ss.freq_interval = 2 THEN 'Monday '
		WHEN ss.freq_type = 32 AND ss.freq_interval = 3 THEN 'Tuesday '
		WHEN ss.freq_type = 32 AND ss.freq_interval = 4 THEN 'Wednesday '
		WHEN ss.freq_type = 32 AND ss.freq_interval = 5 THEN 'Thursday '
		WHEN ss.freq_type = 32 AND ss.freq_interval = 6 THEN 'Friday '
		WHEN ss.freq_type = 32 AND ss.freq_interval = 7 THEN 'Saturday '
		WHEN ss.freq_type = 32 AND ss.freq_interval = 8 THEN 'day '
		WHEN ss.freq_type = 32 AND ss.freq_interval = 9 THEN 'weekday '
		WHEN ss.freq_type = 32 AND ss.freq_interval = 10 THEN 'weekend day '
		ELSE ''
	END
	+CASE
		WHEN ss.freq_type = 16 AND (ss.freq_interval = 1 OR ss.freq_interval = 21 OR ss.freq_interval = 31) THEN 'on '+CAST(ss.freq_interval AS varchar(10))+'st day of month '
		WHEN ss.freq_type = 16 AND (ss.freq_interval = 2 OR ss.freq_interval = 22) THEN 'on '+CAST(ss.freq_interval AS varchar(10))+'nd day of month '
		WHEN ss.freq_type = 16 THEN 'on '+CAST(ss.freq_interval AS varchar(10))+'th day of month '
		ELSE ''
	END
	+CASE
		WHEN ss.freq_type = 8 AND ss.freq_interval&1 = 1 THEN 'Sunday '
		ELSE ''
	END
	+CASE
		WHEN ss.freq_type = 8 AND ss.freq_interval&2 = 2 THEN 'Monday '
		ELSE ''
	END
	+CASE
		WHEN ss.freq_type = 8 AND ss.freq_interval&4 = 4 THEN 'Tuesday '
		ELSE ''
	END
	+CASE
		WHEN ss.freq_type = 8 AND ss.freq_interval&8 = 8 THEN 'Wednesday '
		ELSE ''
	END
	+CASE
		WHEN ss.freq_type = 8 AND ss.freq_interval&16 = 16 THEN 'Thursday '
		ELSE ''
	END
	+CASE
		WHEN ss.freq_type = 8 AND ss.freq_interval&32 = 32 THEN 'Friday '
		ELSE ''
	END
	+CASE
		WHEN ss.freq_type = 8 AND ss.freq_interval&64 = 64 THEN 'Saturday '
		ELSE ''
	END
	+CASE
		WHEN freq_subday_type = 1 THEN 'at '+
			RIGHT('00'+CAST(ss.active_start_time /10000 AS varchar(2)),2)+':'+RIGHT('00'+CAST(ss.active_start_time %10000 /100 AS varchar(2)),2)+':'+
			RIGHT('00'+CAST(ss.active_start_time %100 AS varchar(2)),2)
		WHEN freq_subday_type = 2 THEN 'every '+CAST(ss.freq_subday_interval AS varchar(100))+' seconds between '+
			RIGHT('00'+CAST(ss.active_start_time /10000 AS varchar(2)),2)+':'+RIGHT('00'+CAST(ss.active_start_time %10000 /100 AS varchar(2)),2)+':'+
			RIGHT('00'+CAST(ss.active_start_time %100 AS varchar(2)),2)+' and '+
			RIGHT('00'+CAST(ss.active_end_time /10000 AS varchar(2)),2)+':'+RIGHT('00'+CAST(ss.active_start_time %10000 /100 AS varchar(2)),2)+':'+
			RIGHT('00'+CAST(ss.active_start_time %100 AS varchar(2)),2)
		WHEN freq_subday_type = 4 THEN 'every '+CAST(ss.freq_subday_interval AS varchar(100))+' minutes between '+
			RIGHT('00'+CAST(ss.active_start_time /10000 AS varchar(2)),2)+':'+RIGHT('00'+CAST(ss.active_start_time %10000 /100 AS varchar(2)),2)+':'+
			RIGHT('00'+CAST(ss.active_start_time %100 AS varchar(2)),2)+' and '+
			RIGHT('00'+CAST(ss.active_end_time /10000 AS varchar(2)),2)+':'+RIGHT('00'+CAST(ss.active_start_time %10000 /100 AS varchar(2)),2)+':'+
			RIGHT('00'+CAST(ss.active_start_time %100 AS varchar(2)),2)
		WHEN freq_subday_type = 8 THEN 'every '+CAST(ss.freq_subday_interval AS varchar(100))+' hours between '+
			RIGHT('00'+CAST(ss.active_start_time /10000 AS varchar(2)),2)+':'+RIGHT('00'+CAST(ss.active_start_time %10000 /100 AS varchar(2)),2)+':'+
			RIGHT('00'+CAST(ss.active_start_time %100 AS varchar(2)),2)+' and '+
			RIGHT('00'+CAST(ss.active_end_time /10000 AS varchar(2)),2)+':'+RIGHT('00'+CAST(ss.active_start_time %10000 /100 AS varchar(2)),2)+':'+
			RIGHT('00'+CAST(ss.active_start_time %100 AS varchar(2)),2)
		ELSE ''
	END) AS schedule_desc
	,sjs2.step_id
	,sjs2.step_name
	,sjs2.subsystem AS step_type
	,sjs2.[database_name] AS step_db_context
	,sjs2.command AS step_command
FROM msdb.dbo.sysjobs AS sj
LEFT JOIN msdb.dbo.sysjobschedules AS sjs ON sj.job_id = sjs.job_id
LEFT JOIN msdb.dbo.sysschedules AS ss ON sjs.schedule_id = ss.schedule_id
LEFT JOIN msdb.dbo.sysjobsteps AS sjs2 ON sj.job_id = sjs2.job_id
LEFT JOIN job_history AS jh ON sj.job_id = jh.job_id
WHERE jh.row_no = 1
--	AND jh.step_id = 1
ORDER BY sj.[name] ASC, sjs2.step_id;
