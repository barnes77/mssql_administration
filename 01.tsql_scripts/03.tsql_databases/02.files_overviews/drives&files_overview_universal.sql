/*
Created by: Mateusz Wierzbowski
Creation Date: 2019/07/19-2019/07/26
Aim: Gather information about files ([database_name], state_desc, recovery_model, file_type, log_reuse, ag_group, logical_file, size_mb, free_space_mb, FreeSpace%, drive, drive_space_gb, drive_free_space_gb, driveFreeSpace%)
Compatibility: SQL2000+
!Note for <SQL2008 driveSpace is counted if WMIC Volume is available on OS level
Corrections:
	2020/10/14 - Added info about filegroup, autogrowth and max size
	2020/10/15 - Added info about file extensions to 10% of free space and shrinking logs
	2021/08/12 - Added distintion for SQL2008R2 prior to SP1, to use script for SQL2005
*/
 
USE tempdb;
SET NOCOUNT ON;
 
IF OBJECT_ID('#dba_file_info','U') IS NOT NULL BEGIN DROP TABLE #dba_file_info; END
IF OBJECT_ID('#dba_file_info2','U') IS NOT NULL BEGIN DROP TABLE #dba_file_info2; END
IF OBJECT_ID('#dba_file_info_xp','U') IS NOT NULL BEGIN DROP TABLE #dba_file_info_xp; END
IF OBJECT_ID('#dba_file_info_2000','U') IS NOT NULL BEGIN DROP TABLE #dba_file_info_2000; END
IF OBJECT_ID('#dba_file_info_2005','U') IS NOT NULL BEGIN DROP TABLE #dba_file_info_2005; END
 
DECLARE @query1 nvarchar(2000),@query2 nvarchar(4000);
DECLARE @version int = CAST(SUBSTRING(CONVERT(varchar(40),SERVERPROPERTY('ProductVersion')),1,CHARINDEX('.',CONVERT(varchar(40),SERVERPROPERTY('ProductVersion')))-1) AS int)
	,@version2 varchar(40) = SUBSTRING(CONVERT(varchar(40),SERVERPROPERTY('ProductVersion')),0,CHARINDEX('.',CONVERT(varchar(40),SERVERPROPERTY('ProductVersion')),CHARINDEX('.',CONVERT(varchar(40),SERVERPROPERTY('ProductVersion')))+1))
	,@version3 int = CONVERT(int,REVERSE(
		SUBSTRING(
			REVERSE(CONVERT(varchar(40),SERVERPROPERTY('ProductVersion'))),
			CHARINDEX('.',REVERSE(CONVERT(varchar(40),SERVERPROPERTY('ProductVersion'))))+1,
			CHARINDEX('.',REVERSE(CONVERT(varchar(40),SERVERPROPERTY('ProductVersion'))),3)-CHARINDEX('.',REVERSE(CONVERT(varchar(40),SERVERPROPERTY('ProductVersion'))))-1
			)))
--Step01: Create tables
CREATE TABLE #dba_file_info_xp (
	[line] varchar(2000)
);
CREATE TABLE #dba_file_info (
	[name] varchar(100)
	,physical_name varchar(200)
	,size_mb decimal(20,2)
	,free_space_mb decimal(20,2)
	,growth varchar(100)
	,max_size varchar(100)
	,mb_to_add decimal(20,2)
);
CREATE TABLE #dba_file_info2 (
	[name] varchar(100)
	,physical_name varchar(1000)
	,total_space decimal(20,2)
	,free_space_gb decimal(20,2)
);
CREATE TABLE #dba_file_info_2000 (
	ID int identity(1,1)
	,[database_name] varchar(100)
	,logical_file varchar(100)
	,state_desc sql_variant
	,file_group sysname
	,reovery_model sql_variant
	,file_type varchar(50)
	,log_reuse varchar(50)
	,ag_group varchar(10)
	,size_mb decimal(20,2)
	,free_space_mb decimal(20,2)
	,free_space_perc decimal(20,2)
	,growth varchar(100)
	,max_size varchar(100)
	,drive varchar(100)
	,drive_space_gb decimal(20,2)
	,drivefree_space_gb decimal(20,2)
	,drive_free_space_perc decimal (20,2)
	,mb_to_add decimal(20,2)
	,new_size decimal(20,2)
	,new_free_space_perc decimal(20,2)
	,query_to_extend nvarchar(2000)
	,query_to_shrink_log nvarchar(2000)
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
 
--Step02: Gather Info about DB files
 
IF @version > 8
	BEGIN
	SET @query1 = 'USE [?]
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
	INSERT #dba_file_info
	exec sp_MSforeachdb @query1;
	END
ELSE
	BEGIN
	SET @query1 = 'USE [?]
	SELECT
		[name]
		,REVERSE(LEFT(REVERSE(filename),CHARINDEX(''\'',REVERSE(filename))-1)) AS physical_name
		,CAST((size*1.0/128) AS decimal(20,2)) AS size_mb
		,CAST((size*1.0/128)-(FILEPROPERTY(name, ''SpaceUsed'')*1.0/128) AS decimal(20,2)) AS free_space_mb
		,CAST(CAST((growth*1.0/128) AS decimal(20,2)) AS varchar(100)) +'' MB'' AS growth
		,CASE
			WHEN maxsize = ''0'' THEN ''growth disabled''
			WHEN maxsize = ''-1'' THEN ''Unlimited''
			ELSE CAST((maxsize/128) AS varchar(500))+'' MB''
		END AS max_size
		,CAST(((size*1.0/128)+10*((size*1.0/128)-(FILEPROPERTY(name, ''SpaceUsed'')*1.0/128)))/9 AS decimal(20,2)) AS mb_to_add
	FROM dbo.sysfiles';
	INSERT #dba_file_info
	exec sp_MSforeachdb @query1;
	END
--Step03: Gather info about drives and summarize
IF @version > 10
	BEGIN
	SET @query2= '
	INSERT INTO #dba_file_info2
	SELECT
		volume_mount_point AS name
		,physical_name
		,CAST(total_bytes*1.0/(1024*1024*1024) AS decimal(20,2)) AS total_space
		,CAST(available_bytes*1.0/(1024*1024*1024) AS decimal(20,2)) AS free_space_gb
	FROM sys.master_files AS smf
	CROSS APPLY sys.dm_os_volume_stats(smf.database_id, smf.file_id);
 
	SELECT
		sdb.[name] AS [database_name]
		,smf.[name] AS logical_file
		,sdb.state_desc AS state_desc
		,ISNULL(FILEGROUP_NAME(smf.data_space_id),'''') AS dfile_group
		,sdb.recovery_model_desc AS recovery_model
		,CASE
			WHEN smf.[type] = 0 THEN ''data''
			WHEN smf.[type] = 1 THEN ''log''
			ELSE ''other''
		END AS dfile_type
		,CASE
			WHEN smf.[type] = 1 THEN sdb.log_reuse_wait_desc
			ELSE ''''
		END AS log_reuse
		,ISNULL(ag.[name],'''') AS ag_group
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
			ELSE ''0''
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
				THEN ''USE [master] ALTER DATABASE [''+sdb.[name]+''] MODIFY FILE ( Name = N''''''+smf.[name]+'''''', Size = ''
				+ CAST(CEILING((dfi.mb_to_add+dfi.size_mb)/10.0)*10*1024 AS nvarchar(200)) +''KB )''
			ELSE ''''
		END AS query_to_extend
		,CASE
			WHEN smf.[type] = 1 AND sdb.log_reuse_wait_desc =''NOTHING'' THEN ''USE [''+sdb.[name]+''] DBCC SHRINKFILE (N''''''+smf.[name]+'''''' , 0, TRUNCATEONLY)''
			ELSE ''''
		END AS query_to_shrink_log
	FROM sys.databases AS sdb
	LEFT JOIN sys.master_files AS smf ON sdb.database_id = smf.database_id
	LEFT JOIN sys.availability_databases_cluster AS adc ON adc.database_name = sdb.[name]
	LEFT JOIN sys.availability_groups AS ag ON ag.group_id = adc.group_id
	LEFT JOIN #dba_file_info AS dfi ON dfi.[name] = smf.[name] AND dfi.physical_name = smf.physical_name
	LEFT JOIN #dba_file_info2 AS dfi2 ON dfi2.physical_name = smf.physical_name
	ORDER BY sdb.[name], smf.[type], smf.[name]'
	END
ELSE IF @version2 = '10.50' AND @version3 >= 2500
	BEGIN
	SET @query2 = '
	INSERT INTO #dba_file_info2
	SELECT
		volume_mount_point AS name
		,physical_name
		,CAST(total_bytes*1.0/(1024*1024*1024) AS decimal(20,2)) AS total_space
		,CAST(available_bytes*1.0/(1024*1024*1024) AS decimal(20,2)) AS free_space_gb
	FROM sys.master_files AS smf
	CROSS APPLY sys.dm_os_volume_stats(smf.database_id, smf.file_id);
 
	SELECT
		sdb.[name] AS [database_name]
		,smf.[name] AS logical_file
		,sdb.state_desc AS state_desc
		,ISNULL(FILEGROUP_NAME(smf.data_space_id),'''') AS dfile_group
		,sdb.recovery_model_desc AS recovery_model
		,CASE
			WHEN smf.[type] = 0 THEN ''data''
			WHEN smf.[type] = 1 THEN ''log''
			ELSE ''other''
		END AS dfile_type
		,CASE
			WHEN smf.[type] = 1 THEN sdb.log_reuse_wait_desc
			ELSE ''''
		END AS log_reuse
		,ISNULL(ag.[name],'''') AS ag_group
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
			ELSE ''0''
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
				THEN ''USE [master] ALTER DATABASE [''+sdb.[name]+''] MODIFY FILE ( Name = N''''''+smf.[name]+'''''', Size = ''
				+ CAST(CEILING((dfi.mb_to_add+dfi.size_mb)/10.0)*10*1024 AS nvarchar(200)) +''KB )''
			ELSE ''''
		END AS query_to_extend
		,CASE
			WHEN smf.[type] = 1 AND sdb.log_reuse_wait_desc =''NOTHING'' THEN ''USE [''+sdb.[name]+''] DBCC SHRINKFILE (N''''''+smf.[name]+'''''' , 0, TRUNCATEONLY)''
			ELSE ''''
		END AS query_to_shrink_log
	FROM sys.databases AS sdb
	LEFT JOIN sys.master_files AS smf ON sdb.database_id = smf.database_id
	LEFT JOIN sys.availability_databases_cluster AS adc ON adc.database_name = sdb.[name]
	LEFT JOIN sys.availability_groups AS ag ON ag.group_id = adc.group_id
	LEFT JOIN #dba_file_info AS dfi ON dfi.[name] = smf.[name] AND dfi.physical_name = smf.physical_name
	LEFT JOIN #dba_file_info2 AS dfi2 ON dfi2.physical_name = smf.physical_name
	--Choose DBs
	--WHERE sdb.[name] = ''tempdb''
	--Choose 0 for data files or 1 for log files
	--WHERE smf.[type] = 1
	--Choose drive name
	--WHERE dfi2.[name] LIKE ''%E:%''
	--Choose AG group
	--WHERE ag.[name] LIKE ''%%''
	ORDER BY sdb.[name], smf.[type], smf.[name];'
	END
ELSE IF @version > 8
	BEGIN
	SET @query2 = '
	DECLARE @v_cmdshell sql_variant, @v_advanced_options sql_variant;
	SELECT @v_advanced_options = value FROM sys.configurations WHERE [name] = ''show advanced options'';
	SELECT @v_cmdshell = value FROM sys.configurations WHERE [name] = ''xp_cmdshell'';
 
	IF @v_cmdshell = 0
	BEGIN
		IF @v_advanced_options = 0
			BEGIN
				exec sp_configure ''show advanced options'', 1;
				RECONFIGURE;
				exec sp_configure ''xp_cmdshell'', 1;
				RECONFIGURE;
			END
		ELSE
			BEGIN
				exec sp_configure ''xp_cmdshell'', 1;
				RECONFIGURE;
			END
	END
 
	INSERT INTO #dba_file_info_xp
	exec xp_cmdshell ''wmic /node:"%COMPUTERNAME%" Volume Where driveType="3" Get Capacity,FreeSpace,Name'';
 
	INSERT INTO #dba_file_info_2
	SELECT
		LEFT(RIGHT([line],LEN([line])-CHARINDEX('':'',[line])+2),CHARINDEX('' '',RIGHT([line],LEN([line])-CHARINDEX('':'',[line])+2))-1) AS [name]
		,'''' AS physical_name
		,CAST((CAST(LEFT([line],CHARINDEX('' '',[line])-1) AS decimal(20,2))*1.0/(1024*1024*1024)) AS decimal(20,2))AS total_space
		,CAST((CAST(LTRIM(RTRIM(LEFT(LTRIM(RIGHT([line],LEN([line])-CHARINDEX('' '',[line])-1)),CHARINDEX('' '',LTRIM(RIGHT([line],LEN([line])-CHARINDEX('' '',[line])-1)))))) AS decimal(20,2))*1.0/(1024*1024*1024)) AS decimal(20,2)) AS free_space_gb
	FROM #dba_file_info_xp WHERE [line] LIKE ''%:%'';
	IF @v_cmdshell = 0
	BEGIN
		IF @v_advanced_options = 0
			BEGIN
				exec sp_configure ''xp_cmdshell'', 0;
				RECONFIGURE;
				exec sp_configure ''show advanced options'', 0;
				RECONFIGURE;
			END
		ELSE
			BEGIN
				exec sp_configure ''xp_cmdshell'', 0;
				RECONFIGURE;
			END
	END
	INSERT INTO #dba_file_info_2005
	SELECT
		sdb.[name] AS [database_name]
		,smf.[name] AS logical_file
		,sdb.state_desc AS state_desc
		,ISNULL(FILEGROUP_NAME(smf.data_space_id),'''') AS dfile_group
		,sdb.recovery_model_desc AS recovery_model
		,CASE
			WHEN smf.[type] = 0 THEN ''data''
			WHEN smf.[type] = 1 THEN ''log''
			ELSE ''other''
		END AS dfile_type
		,CASE
			WHEN smf.[type] = 1 THEN sdb.log_reuse_wait_desc
			ELSE ''''
		END AS log_reuse
		,'''' AS ag_group
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
			ELSE ''0''
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
				THEN ''USE [master] ALTER DATABASE [''+sdb.[name]+''] MODIFY FILE ( Name = N''''''+smf.[name]+'''''', Size = ''
				+ CAST(CEILING((dfi.mb_to_add+dfi.size_mb)/10.0)*10*1024 AS nvarchar(200)) +''KB )''
			ELSE ''''
		END AS query_to_extend
		,CASE
			WHEN smf.[type] = 1 AND sdb.log_reuse_wait_desc =''NOTHING'' THEN ''USE [''+sdb.[name]+''] DBCC SHRINKFILE (N''''''+smf.[name]+'''''' , 0, TRUNCATEONLY)''
			ELSE ''''
		END AS query_to_shrink_log
		,ROW_NUMBER() OVER(PARTITION BY sdb.[name], smf.[name] ORDER BY sdb.[name],smf.[name],dfi2.[name] DESC) AS row_no
	FROM sys.databases AS sdb
	LEFT JOIN sys.master_files AS smf ON sdb.database_id = smf.database_id
	LEFT JOIN #dba_file_info AS dfi ON dfi.[name] = smf.[name] AND dfi.physical_name = smf.physical_name
	LEFT JOIN #dba_file_info_2 AS dfi2 ON dfi2.[name] = LEFT (smf.physical_name,LEN(dfi2.[name]))
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
	FROM #dba_file_info_2005 WHERE row_no = 1
	ORDER BY [database_name],file_type,logical_file;'
	END
ELSE
	BEGIN
	SET @query2 = '
	INSERT INTO #dba_file_info_xp
	exec xp_cmdshell ''wmic /node:"%COMPUTERNAME%" Volume Where driveType="3" Get Capacity,FreeSpace,Name'';
 
	INSERT INTO #dba_file_info2
	SELECT
		LEFT(RIGHT([line],LEN([line])-CHARINDEX('':'',[line])+2),CHARINDEX('' '',RIGHT([line],LEN([line])-CHARINDEX('':'',[line])+2))-1) AS [name]
		,'''' AS physical_name
		,CAST((CAST(LEFT([line],CHARINDEX('' '',[line])-1) AS decimal(20,2))*1.0/(1024*1024*1024)) AS decimal(20,2))AS total_space
		,CAST((CAST(LTRIM(RTRIM(LEFT(LTRIM(RIGHT([line],LEN([line])-CHARINDEX('' '',[line])-1)),CHARINDEX('' '',LTRIM(RIGHT([line],LEN([line])-CHARINDEX('' '',[line])-1)))))) AS decimal(20,2))*1.0/(1024*1024*1024)) AS decimal(20,2)) AS free_space_gb
	FROM #dba_file_info_xp WHERE [line] LIKE ''%:%'' AND [line] NOT LIKE ''%ERROR%'';
	--Step4:Join all data
	INSERT INTO #dba_file_info_2000
	SELECT
		sdb.[name] AS [database_name]
		,smf.[name] AS logical_file
		,DATABASEPROPERTYEX(sdb.[name], ''Status'') AS state_desc
		,ISNULL(FILEGROUP_NAME(smf.groupid),'''') AS dfile_group
		,DATABASEPROPERTYEX(sdb.[name], ''Recovery'') AS reovery_model
		,CASE
			WHEN smf.filename LIKE ''%mdf%'' THEN ''data''
			WHEN smf.filename LIKE ''%ndf%'' THEN ''data''
			WHEN smf.filename LIKE ''%ldf%'' THEN ''log''
			ELSE ''other''
		END AS dfile_type
		,'''' AS log_reuse
		,'''' AS ag_group
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
		,dfi2.free_space_gb AS drivefree_space_gb
		,CAST(dfi2.free_space_gb*100/dfi2.total_space AS decimal(20,2)) AS drive_free_space_perc
		,CASE
			WHEN (dfi.free_space_mb*100/dfi.size_mb) < 10 THEN dfi.mb_to_add
			ELSE ''0''
		END AS mb_to_add
		,CASE
			WHEN (dfi.free_space_mb*100/dfi.size_mb) < 10 THEN CEILING((dfi.mb_to_add+dfi.size_mb)/10.0)*10
			ELSE dfi.size_mb
		END AS new_size
		,CASE
			WHEN (dfi.free_space_mb*100/dfi.size_mb) < 10 THEN CAST((dfi.free_space_mb+dfi.mb_to_add)/(CEILING((dfi.mb_to_add+dfi.size_mb)/10.0)*10)*100 AS decimal(20,2))
			ELSE CAST(dfi.free_space_mb*100/dfi.size_mb AS decimal(20,2))
		END AS new_free_space_perc
		,CASE
			WHEN (dfi.free_space_mb*100/dfi.size_mb) < 10
				THEN ''USE [master] ALTER DATABASE [''+sdb.[name]+''] MODIFY FILE ( Name = N''''''+smf.[name]+'''''', Size = ''
				+ CAST(CEILING((dfi.mb_to_add+dfi.size_mb)/10.0)*10*1024 AS nvarchar(200)) +''KB )''
			ELSE ''''
		END AS query_to_extend
		,CASE
			WHEN smf.filename LIKE ''%ldf%'' THEN ''USE [''+sdb.[name]+''] DBCC SHRINKFILE (N''''''+smf.[name]+'''''' , 0, TRUNCATEONLY)''
			ELSE ''''
		END AS query_to_shrink_log
	FROM [master].dbo.sysdatabases AS sdb
	LEFT JOIN [master].dbo.sysaltfiles AS smf ON sdb.dbid = smf.dbid
	LEFT JOIN #dba_file_info AS dfi ON dfi.[name] = smf.[name]
	LEFT JOIN #dba_file_info2 AS dfi2 ON dfi2.[name] = LEFT (smf.filename,LEN(dfi2.[name]))
	ORDER BY sdb.[name] ASC, dfi2.[name] DESC;
	SELECT
		[database_name]
		,logical_file
		,state_desc
		,file_group
		,reovery_model
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
		,drivefree_space_gb
		,drive_free_space_perc
		,mb_to_add
		,new_size
		,new_free_space_perc
		,query_to_extend
		,query_to_shrink_log
	FROM #dba_file_info_2000
	WHERE ID IN (SELECT MAX(ID) FROM #dba_file_info_2000 GROUP BY [database_name],logical_file)
	ORDER BY [database_name],[file_type],logical_file;'
	END
 
exec (@query2);
 
DROP TABLE #dba_file_info;
DROP TABLE #dba_file_info2;
DROP TABLE #dba_file_info_xp;
DROP TABLE #dba_file_info_2000;
DROP TABLE #dba_file_info_2005;
