/*
Created by: Mateusz Wierzbowski
Creation Date: 2019/07/19-2019/07/26
Aim: Gather information about files ([database_name], state_desc, reovery_model, file_type, log_reuse, ag_group, logical_file, size_mb, free_space_mb, FreeSpace%, drive, drive_space_gb, drivefree_space_gb, driveFreeSpace%)
Compatibility: SQL2000
!Note for <SQL2008 driveSpace is counted if WMIC Volume is available on OS level
Corrections:
	2020/10/14 - Added info about filegroup, autogrowth and max size
	2020/10/15 - Added info about file extensions to 10% of free space and shrinking logs
*/
USE tempdb;
SET NOCOUNT ON;
 
IF OBJECT_ID('#dba_file_info','U') IS NOT NULL BEGIN DROP TABLE #dba_file_info; END
IF OBJECT_ID('#dba_file_info2','U') IS NOT NULL BEGIN DROP TABLE #dba_file_info2; END
IF OBJECT_ID('#dba_file_info_xp','U') IS NOT NULL BEGIN DROP TABLE #dba_file_info_xp; END
IF OBJECT_ID('#dba_file_info_2000','U') IS NOT NULL BEGIN DROP TABLE #dba_file_info_2000; END
 
--Step1: Create tables and variables
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
CREATE TABLE #dba_file_info_xp (
	[line] varchar(2000)
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
 

--QUERY ITSELF
 
--Step2: Gather Info about DBFiles
INSERT #dba_file_info
exec sp_MSforeachdb 'USE [?]
	SELECT
		[name]
		,REVERSE(LEFT(REVERSE(filename),CHARINDEX(''\'',REVERSE(filename))-1)) AS physical_name
		,CAST((size*1.0/128) AS decimal(20,2)) AS size_mb
		,CAST((size*1.0/128)-(FILEPROPERTY([name], ''SpaceUsed'')*1.0/128) AS decimal(20,2)) AS free_space_mb
		,CAST(CAST((growth*1.0/128) AS decimal(20,2)) AS varchar(100)) +'' MB'' AS growth
		,CASE
			WHEN maxsize = ''0'' THEN ''growth disabled''
			WHEN maxsize = ''-1'' THEN ''Unlimited''
			ELSE CAST((maxsize/128) AS varchar(500))+'' MB''
		END AS max_size
		,CAST(((size*1.0/128)+10*((size*1.0/128)-(FILEPROPERTY([name], ''SpaceUsed'')*1.0/128)))/9 AS decimal(20,2)) AS mb_to_add
	FROM dbo.sysfiles';
 

--Step3: Gather Info about drives
INSERT INTO #dba_file_info_xp
	exec xp_cmdshell 'wmic /node:"%COMPUTERNAME%" Volume Where driveType="3" Get Capacity,FreeSpace,Name';
 
INSERT INTO #dba_file_info2
SELECT
	LEFT(RIGHT([line],LEN([line])-CHARINDEX(':',[line])+2),CHARINDEX(' ',RIGHT([line],LEN([line])-CHARINDEX(':',[line])+2))-1) AS [name]
	,'' AS physical_name
	,CAST((CAST(LEFT([line],CHARINDEX(' ',[line])-1) AS decimal(20,2))*1.0/(1024*1024*1024)) AS decimal(20,2))AS total_space
	,CAST((CAST(LTRIM(RTRIM(LEFT(LTRIM(RIGHT([line],LEN([line])-CHARINDEX(' ',[line])-1)),CHARINDEX(' ',LTRIM(RIGHT([line],LEN([line])-CHARINDEX(' ',[line])-1)))))) AS decimal(20,2))*1.0/(1024*1024*1024)) AS decimal(20,2)) AS free_space_gb
FROM #dba_file_info_xp WHERE [line] LIKE '%:%' AND [line] NOT LIKE '%ERROR%';
--Step4:Join all data
INSERT INTO #dba_file_info_2000
SELECT
	sdb.[name] AS [database_name]
	,mf.[name] AS logical_file
	,DATABASEPROPERTYEX(sdb.[name], 'Status') AS state_desc
	,ISNULL(FILEGROUP_NAME(mf.groupid),'') AS file_group
	,DATABASEPROPERTYEX(sdb.[name], 'Recovery') AS reovery_model
	,CASE
		WHEN mf.[filename] LIKE '%mdf%' THEN 'data'
		WHEN mf.[filename] LIKE '%ndf%' THEN 'data'
		WHEN mf.[filename] LIKE '%ldf%' THEN 'log'
		ELSE 'other'
	END AS file_type
	,'' AS log_reuse
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
	,dfi2.free_space_gb AS drivefree_space_gb
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
		WHEN (dfi.free_space_mb*100/dfi.size_mb) < 10 THEN CAST((dfi.free_space_mb+dfi.mb_to_add)/(CEILING((dfi.mb_to_add+dfi.size_mb)/10.0)*10)*100 AS decimal(20,2))
		ELSE CAST(dfi.free_space_mb*100/dfi.size_mb AS decimal(20,2))
	END AS new_free_space_perc
	,CASE
		WHEN (dfi.free_space_mb*100/dfi.size_mb) < 10
			THEN 'USE [master] ALTER DATABASE ['+sdb.[name]+'] MODIFY FILE ( Name = N'''+mf.[name]+''', Size = '
			+ CAST(CEILING((dfi.mb_to_add+dfi.size_mb)/10.0)*10*1024 AS nvarchar(200)) +'KB )'
		ELSE ''
	END AS query_to_extend
	,CASE
		WHEN mf.[filename] LIKE '%ldf%' THEN 'USE ['+sdb.[name]+'] DBCC SHRINKFILE (N'''+mf.[name]+''' , 0, TRUNCATEONLY)'
		ELSE ''
	END AS query_to_shrink_log
FROM [master].dbo.sysdatabases AS sdb
LEFT JOIN [master].dbo.sysaltfiles AS mf ON sdb.dbid = mf.dbid
LEFT JOIN #dba_file_info AS dfi ON dfi.[name] = mf.[name]
LEFT JOIN #dba_file_info2 AS dfi2 ON dfi2.[name] = LEFT (mf.[filename],LEN(dfi2.[name]))
ORDER BY sdb.[name] ASC, dfi2.[name] DESC;
--Step5: Summarize
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
ORDER BY [database_name],[file_type],logical_file;
 
DROP TABLE #dba_file_info;
DROP TABLE #dba_file_info2;
DROP TABLE #dba_file_info_xp;
DROP TABLE #dba_file_info_2000;
