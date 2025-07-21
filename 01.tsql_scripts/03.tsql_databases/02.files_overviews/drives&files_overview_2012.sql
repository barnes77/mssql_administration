/*
Created by: Mateusz Wierzbowski
Creation Date: 2019/07/19-2019/07/26
Aim: Gather information about files ([database_name], state_desc, recovery_model, FileType, log_reuse, AGgroup, logical_file, size_mb, free_space_mb, FreeSpace%, drive, drive_space_gb, drive_free_space_gb, driveFreeSpace%)
Compatibility: SQL2012
Corrections:
	2020/10/14 - Added info about filegroup, autogrowth and max size
	2020/10/15 - Added info about file extensions to 10% of free space and shrinking logs
*/
USE tempdb;
SET NOCOUNT ON;
 
IF OBJECT_ID('#dba_file_info','U') IS NOT NULL BEGIN DROP TABLE #dba_file_info; END
IF OBJECT_ID('#dba_file_info2','U') IS NOT NULL BEGIN DROP TABLE #dba_file_info2; END
 
--Step1: Create tables and variables
 
CREATE TABLE #dba_file_info (
	[name] nvarchar(100)
	,physical_name nvarchar(1000)
	,size_mb decimal(20,2)
	,free_space_mb decimal(20,2)
	,growth nvarchar(200)
	,max_size nvarchar(200)
	,mb_to_add decimal(20,2)
);
CREATE TABLE #dba_file_info2 (
	[name] sysname
	,physical_name nvarchar(1000)
	,total_space decimal(20,2)
	,free_space_gb decimal(20,2)
);
 
--QUERY ITSELF
 

--Step2: Gather Info about DBFiles
INSERT #dba_file_info
exec sp_MSforeachdb 'USE [?]
	SELECT
		[name]
		,physical_name
		,(size*1.0/128) AS size_mb
		,(size*1.0/128)-(FILEPROPERTY([name], ''SpaceUsed'')*1.0/128) AS free_space_mb
		,CASE
			WHEN growth = 0 THEN CAST(''0'' AS nvarchar(500))
			WHEN is_percent_growth = 1 THEN CAST(CAST(growth AS decimal(20,2)) AS nvarchar(500))+ '' %''
			WHEN is_percent_growth = 0 THEN CAST(CAST((growth*8/1024.0) AS decimal(20,2)) AS nvarchar(500))+ '' MB''
		END AS growth
		,CASE
			WHEN max_size = ''0'' THEN ''growth disabled''
			WHEN max_size = ''-1'' THEN ''Unlimited''
			ELSE CAST((max_size/128) AS nvarchar(500))+'' MB''
		END AS max_size
		,CAST(((size*1.0/128)+10*((size*1.0/128)-(FILEPROPERTY([name], ''SpaceUsed'')*1.0/128)))/9 AS decimal(20,2)) AS MBToAdd
	FROM sys.database_files';
	
--Step3: Gather Info about drives		
INSERT INTO #dba_file_info2
SELECT
	volume_mount_point AS name
	,physical_name
	,CAST(total_bytes*1.0/(1024*1024*1024) AS decimal(20,2)) AS total_space
	,CAST(available_bytes*1.0/(1024*1024*1024) AS decimal(20,2)) AS free_space_gb
FROM sys.master_files AS smf
CROSS APPLY sys.dm_os_volume_stats(smf.database_id, smf.file_id);
 
--Step4: Summarize
 
SELECT
	sdb.[name] AS [database_name]
	,smf.[name] AS logical_file
	,sdb.state_desc AS state_desc
	,ISNULL(FILEGROUP_NAME(smf.data_space_id),'') AS file_group
	,sdb.recovery_model_desc AS recovery_model
	,CASE
		WHEN smf.[type] = 0 THEN 'data'
		WHEN smf.[type] = 1 THEN 'log'
		ELSE 'other'
	END AS file_type
	,CASE
		WHEN smf.[type] = 1 THEN sdb.log_reuse_wait_desc
		ELSE ''
	END AS log_reuse
	,ISNULL(ag.[name],'') AS ag_group
	,dfi.size_mb AS size_mb
	,dfi.free_space_mb AS free_space_mb
	,CASE
		WHEN dfi.free_space_mb = 0 THEN 0
		ELSE CAST(dfi.free_space_mb*100/dfi.size_mb AS decimal(20,2))
	END AS free_space_perc
	,dfi.growth
	,dfi.max_size
	,dfi2.[name] AS drive
	,dfi2.total_space AS drive_space_gb
	,dfi2.free_space_gb AS drive_free_space_gb
	,CAST(dfi2.free_space_gb*100/dfi2.total_space AS decimal(20,2)) AS drive_free_space_perc
	,CASE
		WHEN (dfi.free_space_mb*100/dfi.size_mb) < 10
			THEN dfi.mb_to_add
		ELSE '0'
	END AS mb_to_add
	,CASE
		WHEN (dfi.free_space_mb*100/dfi.size_mb) < 10
			THEN CEILING((dfi.mb_to_add+dfi.size_mb)/10.0)*10
		ELSE dfi.size_mb
	END AS new_size
	,CASE
		WHEN (dfi.free_space_mb*100/dfi.size_mb) < 10
			THEN CAST((dfi.free_space_mb+dfi.mb_to_add)/(CEILING((dfi.mb_to_add+dfi.size_mb)/10.0)*10)*100 AS decimal(20,2))
		ELSE CAST(dfi.free_space_mb*100/dfi.size_mb AS decimal(20,2))
	END AS new_free_space_perc
	,CASE
		WHEN (dfi.free_space_mb*100/dfi.size_mb) < 10
			THEN 'USE [master] ALTER DATABASE ['+sdb.[name]+'] MODIFY FILE ( Name = N'''+smf.[name]+''', Size = '
			+ CAST(CEILING((dfi.mb_to_add+dfi.size_mb)/10.0)*10*1024 AS nvarchar(200)) +'KB )'
		ELSE ''
	END AS query_to_extend
	,CASE
		WHEN smf.[type] = 1 AND sdb.log_reuse_wait_desc ='NOTHING' THEN 'USE ['+sdb.[name]+'] DBCC SHRINKFILE (N'''+smf.[name]+''' , 0, TRUNCATEONLY)'
		ELSE ''
	END AS query_to_shrink_log
	,CASE
		WHEN dfi.free_space_mb = 0 THEN ''
		WHEN CAST(dfi.free_space_mb*100/dfi.size_mb AS decimal(20,2)) > 10.01 THEN CONCAT('File ',smf.[name],' has ',dfi.free_space_mb,' MB (',CAST(dfi.free_space_mb*100/dfi.size_mb AS decimal(20,2)),'%) of free space. No action needed.')
		ELSE ''
	END AS ticket_resolution
FROM sys.databases AS sdb
LEFT JOIN sys.master_files AS smf ON sdb.database_id = smf.database_id
LEFT JOIN sys.availability_databases_cluster AS adc ON adc.database_name = sdb.[name]
LEFT JOIN sys.availability_groups AS ag ON ag.group_id = adc.group_id
LEFT JOIN #dba_file_info AS dfi ON dfi.[name] = smf.[name] AND dfi.physical_name = smf.physical_name
LEFT JOIN #dba_file_info2 AS dfi2 ON dfi2.physical_name = smf.physical_name
WHERE 1=1
--	AND sdb.[name] = 'tempdb' --Choose DBs
--	AND smf.[type] = 1 --Choose 0 for data files or 1 for log files
--	AND dfi2.[name] LIKE '%E:%' --Choose drive name
--	AND ag.[name] LIKE '%%' --Choose AG group
ORDER BY sdb.[name], smf.[type], smf.[name];
 
DROP TABLE #dba_file_info;
DROP TABLE #dba_file_info2;
