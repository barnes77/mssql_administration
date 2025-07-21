/*
Created by Mateusz Wierzbowski
Creation date: 2019/01/23
V1.0: 2019/01/23
V2.0: 2021/09/30
V2.1: 2022/01/24
V2.2: 2022/02/09
Aim: Gather information for all DBs about: recovery model, backup types, performer, size of last backup, dates of 2 last backups, interval between two last backups, log reuse wait, date of last failed backup (full or log) within LAST 28 DAYS
Compatibility: SQL2005+
*/
USE tempdb;
SET NOCOUNT ON;
 
IF OBJECT_ID('#failed_backups_table','U') IS NOT NULL BEGIN DROP TABLE #failed_backups_table; END
IF OBJECT_ID('#failed_backups_table2','U') IS NOT NULL BEGIN DROP TABLE #failed_backups_table2; END
IF OBJECT_ID('#error_log','U') IS NOT NULL BEGIN DROP TABLE #error_log; END
IF OBJECT_ID('#logs_number','U') IS NOT NULL BEGIN DROP TABLE #logs_number; END
 
--Gather info about failed logins from error logs
CREATE TABLE #error_log (	
	log_date datetime
	,process_name nvarchar(40)
	,[message] nvarchar(max)
);
CREATE TABLE #logs_number (
	nr tinyint
	,int_date datetime
	,size int
);
CREATE TABLE #failed_backups_table (
	[date] datetime
	,[type] nvarchar(2000)
	,[database] nvarchar(2000)
);
CREATE TABLE #failed_backups_table2 (
	row_no int
	,[name] nvarchar(2000)
	,[date] datetime NULL
	,[type] nvarchar(2000)
	,[database] nvarchar(2000)
);
 
DECLARE @i tinyint,@max smallint,@end_date smalldatetime,@min_date smalldatetime;
 
SET @i = 0;
SET @end_date = DATEADD(DAY, -28 , GETDATE());
 
INSERT INTO #logs_number
exec sys.xp_enumerrorlogs;
 
SELECT
	@max = MAX(nr)
	,@min_date = MIN(int_date)
FROM #logs_number;
IF (@min_date < @end_date )
	SELECT @max = MAX(nr) FROM #logs_number WHERE int_date >= @end_date;
WHILE (@i <= @max)
BEGIN
	INSERT INTO #error_log
	exec sp_readerrorlog @i, 1, 'BACK', 'failed' ;
	SET @i = @i +1;
END
 
INSERT INTO #failed_backups_table
SELECT
	CONVERT(CHAR(19),log_date,20) AS [date]
	,CASE
		WHEN [message] LIKE 'BACKUP failed to complete the command BACKUP DATABASE% with DIFF%' THEN 'diff'
		WHEN [message] LIKE 'BACKUP failed to complete the command BACKUP DATABASE%' THEN 'full'
		WHEN [message] LIKE 'BACKUP failed to complete the command BACKUP LOG%'THEN 'log'
		ELSE 'Other'
	END AS [type]
	,CASE
		WHEN [message] LIKE 'BACKUP failed to complete the command BACKUP DATABASE% with DIFF%' THEN RTRIM(LTRIM(REPLACE(REPLACE(REPLACE([message],'BACKUP failed to complete the command BACKUP DATABASE',''),'. Check the backup application log for detailed messages.',''),' WITH DIFFERENTIAL','')))
		WHEN [message] LIKE 'BACKUP failed to complete the command BACKUP DATABASE%' THEN RTRIM(LTRIM(REPLACE(REPLACE([message],'BACKUP failed to complete the command BACKUP DATABASE',''),'. Check the backup application log for detailed messages.','')))
		WHEN [message] LIKE 'BACKUP failed to complete the command BACKUP LOG%'THEN RTRIM(LTRIM(REPLACE(REPLACE([message],'BACKUP failed to complete the command BACKUP LOG',''),'. Check the backup application log for detailed messages.','')))
		ELSE RTRIM(LTRIM(REPLACE(REPLACE([message],'BackupDiskFile::CreateMedia: Backup device ''',''),''' failed to create. Operating system error 3(The system cannot find the path specified.).','')))
	END AS [database]
FROM #error_log
ORDER BY log_date DESC;
 
--Combined info about failed backups with sys.databases
INSERT INTO #failed_backups_table2
SELECT
	ROW_NUMBER() OVER ( PARTITION BY sdb.name,[database],[type] ORDER BY [date] DESC ) AS row_no
	,sdb.[name]
	,fbt.[date]
	,fbt.[type]
	,fbt.[database]
FROM #failed_backups_table AS fbt
RIGHT JOIN sys.databases AS sdb ON sdb.name = fbt.[database];
 
--Create CTE
WITH backup_cte AS (
SELECT
	ROW_NUMBER() OVER ( ORDER BY [database_name],[type],backup_finish_date,backup_set_id DESC ) AS row_no2
	,ROW_NUMBER() OVER ( PARTITION BY [database_name], [type] ORDER BY backup_finish_date DESC ) AS row_no3
	,[database_name]
	,recovery_model
	,CASE
		WHEN [type] = 'L' THEN 'log'
		WHEN [type] = 'D' THEN 'full'
		ELSE 'diff'
	END backup_type
	,CASE
		WHEN [type] = 'L' THEN 3
		WHEN [type] = 'D' THEN 1
		ELSE 2
	END backup_type_order
	,CONVERT(CHAR(19),backup_finish_date,20) AS backup_finish
	,[user_name] AS performed_by_user
	,CAST((compressed_backup_size / (1024*1024)) AS DECIMAL(10,2)) AS size_mb
FROM msdb.dbo.backupset
WHERE backup_finish_date > GETDATE()-30 AND is_copy_only = 0
GROUP BY [database_name],recovery_model,[type],backup_set_id,[user_name],compressed_backup_size,backup_finish_date
), backup_cte2 AS (
SELECT
	sdb.[name] AS [database_name]
	,bc1.recovery_model AS rec_mode
	,bc1.backup_type AS backup_type
	,bc1.performed_by_user
	,bc1.size_mb
	,bc1.backup_finish
	,bc2.backup_finish AS previous_backup_finish
	,CASE
		WHEN bc2.backup_finish IS NOT NULL THEN DATEDIFF(hour, bc2.backup_finish, bc1.backup_finish)
		ELSE NULL
	END AS interval_h
	,CASE
		WHEN bc3.backup_finish IS NOT NULL THEN DATEDIFF(hour, bc3.backup_finish, bc2.backup_finish)
		ELSE NULL
	END AS previous_interval_h
	,CASE
		WHEN bc1.backup_type = 'FULL' THEN ''
		WHEN bc1.backup_type = 'DIFF' THEN ''
		ELSE sdb.log_reuse_wait_desc
	END AS log_reuse
	,CASE
		WHEN fbt2.[type]= bc1.backup_type THEN ISNULL(fbt2.[date],'')
		ELSE NULL
	END AS last_failed_backup
	,bc1.backup_type_order
FROM sys.databases AS sdb
LEFT JOIN backup_cte AS bc1 ON sdb.[name] = bc1.[database_name]
LEFT JOIN backup_cte AS bc2 ON bc1.row_no2 = bc2.row_no2+1 AND bc1.[database_name] = bc2.[database_name]
LEFT JOIN backup_cte AS bc3 ON bc2.row_no2 = bc3.row_no2+1 AND bc2.[database_name] = bc3.[database_name]
LEFT JOIN #failed_backups_table2 AS fbt2 ON fbt2.[name] = bc1.[database_name] AND bc1.backup_type = fbt2.[type]
WHERE (bc1.row_no3 = 1 OR bc1.row_no3 IS NULL) AND (fbt2.row_no = 1 OR fbt2.row_no IS NULL) AND sdb.database_id <> 2
)
SELECT
	[database_name]
	,rec_mode
	,backup_type
	,performed_by_user
	,size_mb
	,backup_finish
	,previous_backup_finish
	,interval_h
	,previous_interval_h
	,log_reuse
	,last_failed_backup
	,CASE
		WHEN last_failed_backup IS NULL THEN NULL
		WHEN backup_finish > last_failed_backup AND previous_backup_finish > last_failed_backup AND backup_type = 'log'
			THEN 'Last failed '+backup_type+' of database '+[database_name]+' happened on '+CONVERT(CHAR(19),last_failed_backup,20)
			+'. Afterwards there has been a chain of successful log backups with the latest one on '+CONVERT(CHAR(19),backup_finish,20)
		WHEN backup_finish > last_failed_backup
			THEN 'Last failed '+backup_type+' of database '+[database_name]+' happened on '+CONVERT(CHAR(19),last_failed_backup,20)
			+'. The latest successful one taken on '+CONVERT(CHAR(19),backup_finish,20)
		ELSE NULL
	END AS ticket_resolution
FROM backup_cte2
WHERE 1=1
--	AND [database_name] = ''
--	AND [database_name] LIKE '%%'
--	AND backup_type = '' --full,diff,log
--	AND last_failed_backup IS NOT NULL
--	AND ticket_resolution IS NOT NULL
ORDER BY [database_name],backup_type_order,backup_finish DESC;
--ORDER BY backup_finish ASC;
 
DROP TABLE #error_log;
DROP TABLE #logs_number;
DROP TABLE #failed_backups_table;
DROP TABLE #failed_backups_table2;
