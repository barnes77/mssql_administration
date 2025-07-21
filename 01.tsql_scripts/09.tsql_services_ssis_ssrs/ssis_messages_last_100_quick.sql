SET NOCOUNT ON;
 
SELECT TOP 100
	message_time
	--,package_name
	--,package_path
	,execution_path
	,event_name
	,[message]
FROM SSISDB.[catalog].[event_messages]
WHERE 1=1
--	AND event_name <> 'OnPreValidate'
	AND package_name = '' --package name here
	AND [message] LIKE '%%' --filter on message
ORDER BY message_time DESC
