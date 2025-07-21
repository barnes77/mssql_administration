USE OperationsManager;
SET NOCOUNT ON;
 
SELECT TOP 100
	av.TimeRaised
	,av.MonitoringObjectPath
	,av.MonitoringObjectDisplayName
	,av.Category
	,av.IsMonitorAlert
	--,av.ResolutionState
	,rs.ResolutionStateName
	,av.[Priority]
	,av.Severity
	,av.AlertStringName
FROM dbo.AlertView AS av
LEFT JOIN dbo.MPElementView AS mpev ON av.MonitoringRuleId = mpev.MPElementId
LEFT JOIN dbo.ManagementPackView AS mpv ON mpev.ManagementPackId = mpv.Id
LEFT JOIN dbo.ResolutionState AS rs ON av.ResolutionState = rs.ResolutionState
WHERE 1=1
	AND mpv.[Name] LIKE '%SQL%' --Filter only SQL Management Packs
	AND av.MonitoringObjectDisplayName LIKE '%%' --Exempli gratia: FQDN, instance, database
	--AND av.IsMonitorAlert = 1
ORDER BY av.TimeRaised DESC;
