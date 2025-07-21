/*
Created by: Mateusz Wierzbowski
Creation date: 2019/03/17
Aim: disable SQL Job with a name in the pattern
*/
 
DECLARE @jobtodisable sysname,@query nvarchar(200);
 
--For different SQL job please change the phrase after LIKE
SET @jobtodisable = (SELECT job_id FROM msdb.dbo.sysjobs WHERE [name] LIKE '%monitoring test%');
SET @query = ('exec msdb.dbo.sp_update_job @job_id=N'''+@jobtodisable+''', @enabled=0');
exec sp_sqlexec @query;
