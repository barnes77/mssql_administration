SET NOCOUNT ON;
 
SELECT
	sdb.[name] AS [db_name]
	,sdb.collation_name
	,ssp.[name] AS [owner]
	,mf.[name] AS [file]
	,mf.physical_name
	,CAST((mf.size*8/1024.0) AS Decimal(20,2)) AS size_mb
	,CASE
		WHEN mf.growth = 0 THEN '0'
		WHEN mf.is_percent_growth = 1 THEN CAST(CAST(mf.growth AS decimal(20,2)) AS nvarchar(500))+ ' %'
		WHEN mf.is_percent_growth = 0 THEN CAST(CAST((mf.growth*8/1024.0) AS decimal(20,2)) AS nvarchar(500))+ ' MB'
	END AS growth
	,ag.[name] AS ag_grup
FROM sys.databases AS sdb
LEFT JOIN sys.server_principals AS ssp ON sdb.owner_sid = ssp.sid
LEFT JOIN sys.master_files AS mf ON sdb.database_id = mf.database_id
LEFT JOIN sys.availability_databases_cluster AS adc ON adc.database_name = sdb.name
LEFT JOIN sys.availability_groups AS ag ON ag.group_id = adc.group_id;
