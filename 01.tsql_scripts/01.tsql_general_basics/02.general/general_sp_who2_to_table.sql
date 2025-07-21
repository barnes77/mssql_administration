USE tempdb;
SET NOCOUNT ON;
 
IF OBJECT_ID('#temp_sp_who2', 'U') IS NOT NULL BEGIN DROP TABLE #temp_sp_who2; END
 
CREATE TABLE #temp_sp_who2 (
	[spid] int
	,[status] varchar(1000) NULL
	,[login] sysname NULL
	,hostname sysname NULL
	,blk_by sysname NULL
	,[db_name] sysname NULL
	,command varchar(1000) NULL
	,cpu_time int NULL
	,disk_io int NULL
	,last_batch varchar(1000) NULL
	,[program_name] varchar(1000) NULL
	,spid2 int
	,request_id int NULL --comment out for SQL 2000 databases
);
 
INSERT INTO #temp_sp_who2
	exec sp_who2;
 
SELECT * FROM #temp_sp_who2
WHERE 1=1 
--	AND hostname = ''
--	AND [db_name] = ''
--	AND [login] = ''
--	AND [blk_by] <> '  .'
