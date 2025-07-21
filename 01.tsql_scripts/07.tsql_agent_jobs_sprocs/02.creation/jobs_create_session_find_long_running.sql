SET NOCOUNT ON;
 
DECLARE
	@sid int = 0
	,@dur_mins int = 0
	,@dur_hrs int = 0
	,@db sysname = 0
	,@login sysname = 0
	,@start datetime = 0
	,@wait_type nvarchar(60) = 0
	,@wait_time int = 0
	,@msg nvarchar(max)
SELECT TOP 1
	@sid = dmer.session_id
	,@dur_mins = DATEDIFF(minute,dmer.start_time,GETDATE())
	,@dur_hrs = DATEDIFF(hour,dmer.start_time,GETDATE())
	,@db = DB_NAME(dmer.[database_id])
	,@login = SUSER_NAME(dmer.user_id)
	,@start = dmer.start_time
	,@wait_type = dmer.wait_type
	,@wait_time = dmer.wait_time
FROM sys.dm_exec_requests AS dmer
CROSS APPLY sys.dm_exec_sql_text([sql_handle]) AS dmest
--Check settings of DB name and timethreshold
WHERE 1=1
	AND DB_NAME(dmer.[database_id]) = 'YourDB' 
	AND DATEDIFF(minute,dmer.start_time,GETDATE()) > MinuteThreshold
ORDER BY dmer.start_time;
 
IF @sid <> 0
BEGIN
	SELECT @msg = 'Long running session detected ' + CHAR(13) +
		'Session ID ' + CAST(@sid AS nvarchar(10)) + CHAR(13) +
		'Running for ' + CAST(@dur_mins AS nvarchar(60)) + ' minutes (= ' + CAST(@dur_hrs AS nvarchar(60)) + ' hours)' + CHAR(13) +
		'Sesion running under login ' + CAST(@login AS nvarchar(60)) + ' to database ' + CAST(@db AS nvarchar(60)) + CHAR(13) +
		'Start time ' + CAST(@start AS nvarchar(60)) + CHAR(13) +
		'wait_type ' + CAST(@wait_type AS nvarchar(60)) + ' wait_time ' + CAST(@wait_time AS nvarchar(60)) + CHAR(13)
--Update DBMail settings
	exec msdb.dbo_sp_send_dbmail @profile_name = 'ProfileName'
		,@recipients='RecipientEMail'
		,@subject= 'Subject'
		,@body = @msg
		,@body_format = 'TEXT';
END
