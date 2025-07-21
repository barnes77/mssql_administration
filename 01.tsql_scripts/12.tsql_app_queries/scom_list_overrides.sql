USE OperationsManager;
SET NOCOUNT ON;
 
SELECT 
    rv.DisplayName AS WorkFlowName
    --,OverrideName
    ,mo.Value AS OverrideValue
    ,op.OverrideableParameterName AS ParamName
    ,mt.TypeName AS OverrideScope
    ,bme.DisplayName AS InstanceName
    ,bme.Path AS InstancePath
    ,mpv.DisplayName AS ORMPName
    ,mo.LastModified AS LastModified
FROM ModuleOverride AS mo
INNER JOIN OverrideableParameter AS op ON op.OverrideableParameterId = mo.OverrideableParameterId
INNER JOIN ManagementPackView AS mpv ON mpv.Id = mo.ManagementPackId
INNER JOIN RuleView AS rv ON rv.Id = mo.ParentId
INNER JOIN ManagedType AS mt ON mt.managedtypeid = mo.TypeContext
LEFT JOIN BaseManagedEntity AS bme ON bme.BaseManagedEntityId = mo.InstanceContext
WHERE mpv.Sealed = 0 AND mpv.LanguageCode = 'ENU' AND (mt.TypeName LIKE '%SQL%' OR OverrideName LIKE '%Reporting%') AND mpv.DisplayName NOT LIKE '%Warehouse%'
UNION ALL
SELECT 
    mv.DisplayName AS WorkFlowName
    --,OverrideName
    ,mto.Value AS OverrideValue
    ,op.OverrideableParameterName AS ParamName
    ,mt.TypeName AS OverrideScope
    ,bme.DisplayName AS InstanceName
    ,bme.Path AS InstancePath
    ,mpv.DisplayName AS ORMPName
    ,mto.LastModified AS LastModified
FROM MonitorOverride AS mto
INNER JOIN OverrideableParameter AS op ON op.OverrideableParameterId = mto.OverrideableParameterId
INNER JOIN ManagementPackView AS mpv ON mpv.Id = mto.ManagementPackId
INNER JOIN MonitorView AS mv ON mv.Id = mto.MonitorId
INNER JOIN ManagedType AS mt ON mt.managedtypeid = mto.TypeContext
LEFT JOIN BaseManagedEntity AS bme ON bme.BaseManagedEntityId = mto.InstanceContext
WHERE mpv.Sealed = 0 AND mpv.LanguageCode = 'ENU' AND (mt.TypeName LIKE '%SQL%' OR OverrideName LIKE '%Reporting%') AND mpv.DisplayName NOT LIKE '%Warehouse%'
ORDER BY WorkFlowName;
