SET NOCOUNT ON;
 
SELECT
	DB_NAME(database_id) AS [db_name]
	,[type_desc] AS file_type
	,CAST(SUM(CAST(size AS decimal(20,2)))/128.0 AS decimal(38,2)) AS size_mb
	,CAST(SUM(CAST(size AS decimal(20,2)))/128.0/1024 AS decimal(38,2)) AS size_gb
FROM sys.master_files
GROUP BY database_id, [type_desc]
ORDER BY [db_name] ASC , file_type DESC;
