SET NOCOUNT ON;
 
SELECT
	[Total Server Memory (KB)] / 1024 AS total_server_memory_mb
	,[Stolen Server Memory (KB)] / 1024 AS total_stolen_memory_mb
	,CAST(100.0*[Stolen Server Memory (KB)]/[Total Server Memory (KB)] AS decimal(10,2)) AS stolen_memory_perc
FROM (
SELECT
	counter_name
	,cntr_value
FROM sys.dm_os_performance_counters
WHERE counter_name IN ('Total Server Memory (KB)','Stolen Server Memory (KB)')
) AS pivot_source
PIVOT (
	MAX(cntr_value) FOR counter_name IN ([Total Server Memory (KB)],[Stolen Server Memory (KB)])
) AS pivot_table;
