--Run against DB using CDC
exec sys.sp_cdc_help_change_data_capture; --returns CDC configuration information for all tables
 
SET NOCOUNT ON;
 
SELECT TOP 10
	[object_id] AS [object_id]
	,SCHEMA_NAME([schema_id]) AS [schema_name]
	,[name] AS table_name
	,is_tracked_by_cdc
FROM sys.tables;
 
exec sys.sp_cdc_help_jobs; --report for all CDC cleanup or capture jobs
