##Create Event Viewer Tasks for escalating priority of events in Application logs
#Based on script by Xavier Plantefeve at xplantefeve.io/posts/SchdTskOnEvent
##Variables:
#Current event:	EventSource = MSSQL$DB01	EventId = 17126	
#New event:		EventSource = DB01			EventId = 200		Level =	ERROR		Description: SQL Server DB01 started
#Task:			Name = DbaMonitoringForSqlServerDB01	Description: Creates Error Event for Informational Event, so it can be sent to Log Analytics Workspace
 
$Class = Get-CIMClass MSFT_TaskEventTrigger root/Microsoft/Windows/TaskScheduler
$Trigger = $Class | New-CimInstance -ClientOnly
 
$Trigger.Enabled = $true
$Trigger.Subscription = '<QueryList><Query Id="0" Path="Application"><Select Path="Application">*[System[Provider[@Name=''MSSQL$DB01''] and EventID=17126]]</Select></Query></QueryList>'
 
$ActionParameters = @{
	Execute		= 'C:\Windows\System32\eventcreate.exe'
	Argument	= '/l APPLICATION /so DB01 /t ERROR /id 200 /d "SQL Server DB01 started"'
}
 
$Action = New-ScheduledTaskAction @ActionParameters
$Principal = New-ScheduledTaskPrincipal -UserId 'NT AUTHORITY\SYSTEM' -LogonType ServiceAccount
$Settings = New-ScheduledTaskSettingsSet
 
$RegSchTaskParameters = @{
	TaskName		= 'DbaMonitoringForSqlServerDB01'
	Description = 'Creates Error Event for Informational Event, so it can be sent to Log Analytics Workspace'
	TaskPath		= '\Event Viewer Tasks\'
	Action			= $Action
	Principal	= $Principal
	Settings		= $Settings
	Trigger		= $Trigger
}
 
Register-ScheduledTask @RegSchTaskParameters
