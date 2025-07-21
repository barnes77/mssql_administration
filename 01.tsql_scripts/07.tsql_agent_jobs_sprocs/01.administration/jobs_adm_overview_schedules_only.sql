/*
Created by Mateusz Wierzbowski
Creation date: 2020/08/04
Compatibility: SQL2005+
Aim: provide a list of SQL jobs schedules with the schedule description
*/
SELECT
	ss.[name] AS schedule_name
	,ss.[schedule_id]
	,ss.[enabled] AS schedule_status
	,CASE
		WHEN ss.freq_type = 1 THEN 'Single run'
		WHEN ss.freq_type = 4 THEN 'Daily'
		WHEN ss.freq_type = 8 THEN 'Weekly'
		WHEN ss.freq_type = 16 OR ss.freq_type = 32 THEN 'Monthly'
		WHEN ss.freq_type = 64 THEN 'On Agent startup'
		WHEN ss.freq_type = 128 THEN 'Computer idle'
		ELSE ''
	END AS [schedule_type]
	,(
	CASE
		WHEN ss.freq_type = 4 THEN 'Occurs every '
		WHEN ss.freq_type = 8 THEN 'Occurs every '
		WHEN ss.freq_type = 16 THEN 'Occurs every '
		WHEN ss.freq_type = 32 THEN 'Occurs every '
		ELSE ''
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
FROM msdb.dbo.sysschedules AS ss
WHERE ss.[enabled] = 1
ORDER BY ss.[name] ASC;
--ORDER BY ss.freq_type, ss.[name] ASC;
