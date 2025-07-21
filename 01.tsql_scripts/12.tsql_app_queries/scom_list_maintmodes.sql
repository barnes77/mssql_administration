USE OperationsManagerDW;
SET NOCOUNT ON;
 
SELECT DISTINCT 
	DisplayName
	,StartDateTime as start_datetime_utc
	,EndDateTime as end_datetime_utc
FROM ManagedEntity AS me WITH (NOLOCK)
INNER JOIN MaintenanceMode AS mm ON me.ManagedEntityRowId = mm.ManagedEntityRowId
INNER JOIN MaintenanceModeHistory AS mmh ON mm.MaintenanceModeRowId = mmh.MaintenanceModeRowId
WHERE DisplayName LIKE '%HTSQCT1%'
--AND StartDateTime < '2022-10-28 14:00:00.000'
--AND EndDateTime > '2022-10-31 08:00:00.000'
ORDER BY StartDateTime DESC;
