USE OperationsManager;
SET NOCOUNT ON;
 
SELECT TOP 10 
	ev.TimeGenerated
	,ev.MonitoringObjectPath
	,ev.MonitoringObjectDisplayName
	,ev.Id
FROM EventView ev
LEFT JOIN dbo.MPElementView AS mpev ON ev.RuleId = mpev.MPElementId
LEFT JOIN dbo.ManagementPackView AS mpv ON mpev.ManagementPackId = mpv.Id
WHERE 1=1
	AND mpv.[Name] LIKE '%SQL%' --Filter only SQL Management Packs
	AND ev.MonitoringObjectDisplayName LIKE '%%' --Exempli gratia: FQDN, instance, database
ORDER BY TimeGenerated DESC;
