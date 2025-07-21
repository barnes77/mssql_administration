/*
Based on script by Aaron Bertrand
Source: sqlblog.org/2007/01/11/reviewing-autogrow-events-from-the-default-trace
Modified by Mateusz Wierzbowski
Date of modification: 2019/07/23
Aim: Check when server roles were altered
*/
SET NOCOUNT ON;
 
DECLARE @path NVARCHAR(260);
 
SELECT
	@path = REVERSE(SUBSTRING(REVERSE([path]),CHARINDEX('\', REVERSE([path])), 260)) + N'log.trc'
FROM sys.traces
WHERE is_default = 1;
 
SELECT
	LEFT(
		REPLACE(CAST(TextData AS nvarchar(1000)),'alter server role [','')
		,CHARINDEX(']',REPLACE(CAST(TextData AS nvarchar(1000)),'alter server role [',''))-1
		) AS server_role
	,CASE
		WHEN CHARINDEX('add member',CAST(TextData AS nvarchar(1000))) > 0 THEN 'Granted'
		WHEN CHARINDEX('drop member',CAST(TextData AS nvarchar(1000))) > 0 THEN 'Revoked'
		WHEN CHARINDEX('with name',CAST(TextData AS nvarchar(1000))) > 0 THEN 'Role name changed'
	END AS [modification]
	,TargetLoginName AS modified_for
	,LoginName AS modified_by
	,StartTime AS modified_on
FROM sys.fn_trace_gettable(@path, DEFAULT)
WHERE 1=1 
	AND EventClass IN (108) 
	AND LOWER(CAST(TextData AS nvarchar(1000))) NOT LIKE 'alter server role [public]%'
ORDER BY StartTime DESC;
