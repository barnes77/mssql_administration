/*
Created by: Mateusz Wierzbowski
Creation Date: 2019/07/19-2019/07/26
Aim: Gather information about files ([database_name], state_desc, recovery_model, FileType, log_reuse, ag_group, logical_file, size_mb, free_space_mb, FreeSpace%, drive, drive_space_gb, drive_free_space_gb, driveFreeSpace%)
Compatibility: SQL2005
!Note for <SQL2008 driveSpace is counted if WMIC Volume is available on OS level
Corrections:
	2020/10/14 - Added info about filegroup, autogrowth and max size
	2020/10/15 - Added info about file extensions to 10% of free space and shrinking logs
*/
USE tempdb;
SET NOCOUNT ON;
 
IF OBJECT_ID('#dba_file_info','U') IS NOT NULL BEGIN DROP TABLE #dba_file_info; END
IF OBJECT_ID('#dba_file_info_2','U') IS NOT NULL BEGIN DROP TABLE #dba_file_info_2; END
IF OBJECT_ID('#dba_file_info_xp','U') IS NOT NULL BEGIN DROP TABLE #dba_file_info_xp; END
IF OBJECT_ID('#dba_file_info_2005','U') IS NOT NULL BEGIN DROP TABLE #dba_file_info_2005; END
 
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
CREATE TABLE #dba_file_info_2 (
	[name] nvarchar(100)
	,physical_name nvarchar(1000)
	,total_space decimal(20,2)
	,free_space_gb decimal(20,2)
);
CREATE TABLE #dba_file_info_xp (
	[line] varchar(2000)
);
CREATE TABLE #dba_file_info_2005 (
	[database_name] sysname
	,logical_file sysname
	,state_desc nvarchar(60)
	,file_group nvarchar(128)
	,recovery_model nvarchar(60)
	,file_type nvarchar(60)
	,log_reuse nvarchar(60)
	,ag_group nvarchar(128)
	,size_mb decimal(20,2)
	,free_space_mb decimal(20,2)
	,free_space_perc decimal(20,2)
	,growth nvarchar(200)
	,max_size nvarchar(200)
	,drive nvarchar(100)
	,drive_space_gb decimal(20,2)
	,drive_free_space_gb decimal(20,2)
	,drive_free_space_perc decimal(20,2)
	,mb_to_add decimal(20,2)
	,new_size decimal(20,2)
	,new_free_space_perc decimal(20,2)
	,query_to_extend nvarchar(2000)
	,query_to_shrink_log nvarchar(2000)
	,row_no int
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
		,CAST(((size*1.0/128)+10*((size*1.0/128)-(FILEPROPERTY([name], ''SpaceUsed'')*1.0/128)))/9 AS decimal(20,2)) AS mb_to_add
	FROM sys.database_files';
 
--Step3: Gather Info about drives	
DECLARE @v_cmdshell sql_variant, @v_advanced_options sql_variant;
SELECT @v_advanced_options = value FROM sys.configurations WHERE [name] = 'show advanced options';
SELECT @v_cmdshell = value FROM sys.configurations WHERE [name] = 'xp_cmdshell';
 
	--enable XPCmdShell if it is disabled
IF @v_cmdshell = 0
BEGIN
	IF @v_advanced_options = 0
		BEGIN
			exec sp_configure 'show advanced options', 1;
			RECONFIGURE;
			exec sp_configure 'xp_cmdshell', 1;
			RECONFIGURE;
		END
	ELSE
		BEGIN
			exec sp_configure 'xp_cmdshell', 1;
			RECONFIGURE;
		END
END
 
	--this is ithe actual process
 
INSERT INTO #dba_file_info_xp
	exec xp_cmdshell 'wmic /node:"%COMPUTERNAME%" Volume Where driveType="3" Get Capacity,FreeSpace,Name';
 
INSERT INTO #dba_file_info_2
SELECT
	LEFT(RIGHT([line],LEN([line])-CHARINDEX(':',[line])+2),CHARINDEX(' ',RIGHT([line],LEN([line])-CHARINDEX(':',[line])+2))-1) AS [name]
	,'' AS physical_name
	,CAST((CAST(LEFT([line],CHARINDEX(' ',[line])-1) AS decimal(20,2))*1.0/(1024*1024*1024)) AS decimal(20,2))AS total_space
	,CAST((CAST(LTRIM(RTRIM(LEFT(LTRIM(RIGHT([line],LEN([line])-CHARINDEX(' ',[line])-1)),CHARINDEX(' ',LTRIM(RIGHT([line],LEN([line])-CHARINDEX(' ',[line])-1)))))) AS decimal(20,2))*1.0/(1024*1024*1024)) AS decimal(20,2)) AS free_space_gb
FROM #dba_file_info_xp WHERE [line] LIKE '%:%';
 
--if XPCmdShell had been disabled, disable it again
IF @v_cmdshell = 0
BEGIN
	IF @v_advanced_options = 0
		BEGIN
			exec sp_configure 'xp_cmdshell', 0;
			RECONFIGURE;
			exec sp_configure 'show advanced options', 0;
			RECONFIGURE;
		END
	ELSE
		BEGIN
			exec sp_configure 'xp_cmdshell', 0;
			RECONFIGURE;
		END
END
 
--Step4: Summarize
INSERT INTO #dba_file_info_2005
SELECT
	sdb.[name] AS [database_name]
	,mf.[name] AS logical_file
	,sdb.state_desc AS state_desc
	,ISNULL(FILEGROUP_NAME(mf.data_space_id),'') AS file_group
	,sdb.recovery_model_desc AS recovery_model
	,CASE
		WHEN mf.[type] = 0 THEN 'data'
		WHEN mf.[type] = 1 THEN 'log'
		ELSE 'other'
	END AS file_type
	,CASE
		WHEN mf.[type] = 1 THEN sdb.log_reuse_wait_desc
		ELSE ''
	END AS log_reuse
	,'' AS ag_group
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
		WHEN (dfi.free_space_mb*100/dfi.size_mb) < 10 THEN dfi.mb_to_add
		ELSE '0'
	END AS mb_to_add
	,CASE
		WHEN (dfi.free_space_mb*100/dfi.size_mb) < 10 THEN CEILING((dfi.mb_to_add+dfi.size_mb)/10.0)*10
		ELSE dfi.size_mb
	END AS new_size
	,CASE
		WHEN (dfi.free_space_mb*100/dfi.size_mb) < 10
			THEN CAST((dfi.free_space_mb+dfi.mb_to_add)/(CEILING((dfi.mb_to_add+dfi.size_mb)/10.0)*10)*100 AS decimal(20,2))
		ELSE CAST(dfi.free_space_mb*100/dfi.size_mb AS decimal(20,2))
	END AS new_free_space_perc
	,CASE
		WHEN (dfi.free_space_mb*100/dfi.size_mb) < 10
			THEN 'USE [master] ALTER DATABASE ['+sdb.[name]+'] MODIFY FILE ( Name = N'''+mf.[name]+''', Size = '
			+ CAST(CEILING((dfi.mb_to_add+dfi.size_mb)/10.0)*10*1024 AS nvarchar(200)) +'KB )'
		ELSE ''
	END AS query_to_extend
	,CASE
		WHEN mf.[type] = 1 AND sdb.log_reuse_wait_desc ='NOTHING' THEN 'USE ['+sdb.[name]+'] DBCC SHRINKFILE (N'''+mf.[name]+''' , 0, TRUNCATEONLY)'
		ELSE ''
	END AS query_to_shrink_log
	,ROW_NUMBER() OVER(PARTITION BY sdb.[name], mf.[name] ORDER BY sdb.[name],mf.[name],dfi2.[name] DESC) AS row_no
FROM sys.databases AS sdb
LEFT JOIN sys.master_files AS mf ON sdb.database_id = mf.database_id
LEFT JOIN #dba_file_info AS dfi ON dfi.[name] = mf.[name] AND dfi.physical_name = mf.physical_name
LEFT JOIN #dba_file_info_2 AS dfi2 ON dfi2.[name] = LEFT (mf.physical_name,LEN(dfi2.[name]))
ORDER BY sdb.[name], dfi2.[name] DESC;
 
SELECT
	[database_name]
	,logical_file
	,state_desc
	,recovery_model
	,file_group
	,file_type
	,log_reuse
	,ag_group
	,size_mb
	,free_space_mb
	,free_space_perc
	,growth
	,max_size
	,drive
	,drive_space_gb
	,drive_free_space_gb
	,drive_free_space_perc
	,mb_to_add
	,new_size
	,new_free_space_perc
	,query_to_extend
	,query_to_shrink_log
FROM #dba_file_info_2005 
WHERE row_no = 1
ORDER BY [database_name],file_type,logical_file;
 
DROP TABLE #dba_file_info;
DROP TABLE #dba_file_info_2;
DROP TABLE #dba_file_info_xp;
DROP TABLE #dba_file_info_2005;
