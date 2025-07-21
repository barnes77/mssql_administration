/*
Created by: Mateusz Wierzbowski
Creation Date: 2020/10/15
Aim: Gather information about files and verify which ones need to be expanded to have 10% of free space
*/
USE tempdb;
SET NOCOUNT ON;
 
IF OBJECT_ID('#dba_file_extension','U') IS NOT NULL BEGIN DROP TABLE #dba_file_extension; END
 
CREATE TABLE #dba_file_extension (
	[db_name] sysname
	,[file_name] sysname
	,size_mb decimal(20,2)
	,free_space_mb decimal(20,2)
	,free_space_perc decimal(20,2)
	,growth nvarchar(60)
	,max_size nvarchar(60)
	,mb_to_add decimal(20,2)
	,new_size_mb decimal(20,2)
	,new_free_space_perc decimal(20,2)
);
 
INSERT INTO #dba_file_extension
exec sp_Msforeachdb 'USE [?]
SELECT
	DB_NAME() AS [db_name]
	,[name] AS [file_name]
	,CAST(size/128.0 AS decimal(20,2)) AS size_mb
	,CAST(((size/128.0)-(FILEPROPERTY([name], ''SpaceUsed'')/128.0)) AS decimal(20,2)) AS free_space_mb
	,CAST((((size/128.0)-(FILEPROPERTY([name], ''SpaceUsed'')/128.0))/(size/128.0)*100) AS decimal(20,2)) AS free_space_perc
	,CASE
		WHEN growth = 0 THEN CAST(''0'' AS nvarchar(60))
		WHEN is_percent_growth = 1 THEN CAST(CAST(growth AS decimal (20,2)) AS nvarchar(60))+ '' %''
		WHEN is_percent_growth = 0 THEN CAST(CAST((growth*8/1024.0) AS decimal(20,2)) AS nvarchar(60))+ '' MB''
	END AS growth
	,CASE
		WHEN max_size = ''0'' THEN ''growth disabled''
		WHEN max_size = ''-1'' THEN ''Unlimited''
		ELSE CAST((max_size/128) AS nvarchar(60))+'' MB''
	END AS max_size
	,CASE
	WHEN CAST((((size/128.0)-(FILEPROPERTY([name], ''SpaceUsed'')/128.0))/(size/128.0)*100) AS decimal(20,2)) < 10
		THEN CAST(((size/128.0)+10*((size/128.0)-(FILEPROPERTY([name], ''SpaceUsed'')/128.0)))/9 AS decimal(20,2))
	ELSE ''0''
	END AS mb_to_add
	,CASE
	WHEN CAST((((size/128.0)-(FILEPROPERTY([name], ''SpaceUsed'')/128.0))/(size/128.0)*100) AS decimal(20,2)) < 10
		THEN CEILING(CAST((size/128.0)+(((size/128.0)+10*((size/128.0)-(FILEPROPERTY([name], ''SpaceUsed'')/128.0)))/9) AS decimal(20,2)) /10.0) * 10
	ELSE CAST(size/128.0 AS decimal(20,2))
	END AS new_size_mb
	,CASE
	WHEN CAST((((size/128.0)-(FILEPROPERTY([name], ''SpaceUsed'')/128.0))/(size/128.0)*100) AS decimal(20,2)) < 10
		THEN CAST((((size/128.0)-(FILEPROPERTY([name], ''SpaceUsed'')/128.0)+(((size/128.0)+10*((size/128.0)-(FILEPROPERTY([name], ''SpaceUsed'')/128.0)))/9))
			/(size/128.0+(((size/128.0)+10*((size/128.0)-(FILEPROPERTY([name], ''SpaceUsed'')/128.0)))/9))*100) AS decimal(20,2))
	ELSE CAST((((size/128.0)-(FILEPROPERTY([name], ''SpaceUsed'')/128.0))/(size/128.0)*100) AS decimal(20,2))
	END AS new_free_space_perc
FROM sys.database_files';
 
SELECT
	dfe.[db_name]
	,dfe.[file_name]
	,ISNULL(FILEGROUP_NAME(mf.data_space_id),'') AS file_group
	,dfe.size_mb
	,dfe.free_space_mb
	,dfe.free_space_perc
	,dfe.growth
	,dfe.max_size
	,dfe.mb_to_add
	,dfe.new_size_mb
	,dfe.new_free_space_perc
	,dm_ovs.volume_mount_point AS volume_name
	,CAST(dm_ovs.total_bytes*1.0/(1024*1024*1024) AS decimal(20,2)) AS vol_total_space
	,CAST(dm_ovs.available_bytes*1.0/(1024*1024*1024) AS decimal(20,2)) AS vol_free_space_gb
	,CAST((dm_ovs.available_bytes*1.0/(1024*1024*1024))/(dm_ovs.total_bytes*1.0/(1024*1024*1024))*100 AS decimal(20,2)) AS vol_free_space_perc
	,CASE
	WHEN dfe.free_space_perc < 10
		THEN 'USE [master] ALTER DATABASE ['+dfe.[db_name]+'] MODIFY FILE ( Name = N'''+dfe.[file_name]+''', MB = '
		+CAST(dfe.new_size_mb * 1024 AS nvarchar(200))+'KB )'
	ELSE ''
	END AS query_to_expand
FROM #dba_file_extension AS dfe
LEFT JOIN sys.master_files AS mf ON dfe.[db_name] = DB_NAME(mf.database_id) AND dfe.[file_name] = mf.name
CROSS APPLY sys.dm_os_volume_stats(mf.database_id, mf.[file_id]) AS dm_ovs
ORDER BY [db_name] ASC, file_group DESC;
 
DROP TABLE #dba_file_extension;
