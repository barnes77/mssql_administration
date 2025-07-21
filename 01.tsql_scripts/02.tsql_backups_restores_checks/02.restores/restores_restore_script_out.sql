/*
Created by: Mateusz Wierzbowski
Creation date: 2020-12-31 / 2021-01-02
Aim: Create a restore script based on backup history of the source database
Corrections:
	2021/04/06 - corrected duplicated "with" in case of restore options, corrected syntax for powershell to check if the files still exist
*/
SET NOCOUNT ON;
 
--declare variables
DECLARE @database varchar(200),@target_database varchar(200),@point_in_time datetime=NULL,@recovery_mod varchar(200),@not_log int,@no_recovery int
	,@mediaset_full int,@mediaset_nextfull int,@mediaset_diff int,@mediaset_log_min int,@mediaset_log_max int
	,@full_file nvarchar(2000),@diff_file nvarchar(2000),@log_file nvarchar(max),@last_log_file nvarchar(2000),@db_file nvarchar(2000)
	,@powers1 nvarchar(1000),@powers2 nvarchar(1000),@powers3 nvarchar(max),@powers4 nvarchar(1000);
DECLARE @logmediaset TABLE (media_set_id int);
DECLARE @full_files TABLE (physical_device_name nvarchar(260));
DECLARE @diff_files TABLE (physical_device_name nvarchar(260));
DECLARE @log_files TABLE (physical_device_name nvarchar(260), media_set_id int);
 

--this part has necessary settings for the restorescript
SET @database = 'DBNAME';								--Give name of the database that needs to be restored
SET @target_database = '';								--Give name of the target database, if you want to overwrite existing one you can leave it blank
SET @point_in_time = '2021-04-06 18:30:00.000';			--Give timestamp to which you want to restore the database
SET @not_log = 0;										 --Change to 1, if you don't want to restore logs, i.e. if you want to restore full backup only or full and diff backups
SET @no_recovery = 0;									 --Change to 1, if you want to leave the database in RESTORING mode
 
--set default values to variables
IF @point_in_time IS NULL OR @point_in_time = '' BEGIN SET @point_in_time = GETDATE() PRINT N'--Point-in-time not set - corrected to current date'; END
IF @point_in_time IS NOT NULL AND @point_in_time > GETDATE() BEGIN SET @point_in_time = GETDATE() PRINT N'--Point-in-time set to future, corrected to current date'; END
IF @point_in_time < (SELECT MIN(backup_finish_date) FROM msdb.dbo.backupset)
	BEGIN SET @point_in_time = GETDATE() PRINT N'--Point-in-time set prior to the earliest backup finish date in msdb..backupset, corrected to current date'+CHAR(13)+CHAR(10)
	+N'--select min(backup_finish_date) from msdb.dbo.backupset where database = '''+@database+N''''; END
IF @database IS NULL OR @database = '' BEGIN SET @database = 0; END
IF @target_database IS NULL OR @target_database = '' BEGIN SET @target_database = @database; END
SELECT @recovery_mod = recovery_model_desc FROM sys.databases WHERE name = @database;
 
--Find mediaset of the latest full backup before point-in-time
SELECT TOP 1 @mediaset_full = media_set_id FROM msdb.dbo.backupset
	WHERE [database_name] = @database AND is_copy_only = 0 AND [type] = 'D' AND backup_start_date < @point_in_time ORDER BY backup_start_date DESC;
SET @mediaset_full = ISNULL(@mediaset_full,0);
 
--Find mediaset of the latest diff backup before point-in-time
SELECT TOP 1 @mediaset_diff = media_set_id FROM msdb.dbo.backupset
	WHERE [database_name] = @database AND is_copy_only = 0 AND [type] = 'I' AND backup_start_date < @point_in_time ORDER BY backup_start_date DESC;
SET @mediaset_diff=ISNULL(@mediaset_diff,'0');
 
--Find mediaset of the earliest log backup after the latest diff backup or full backup if there are none diffs
SELECT TOP 1 @mediaset_log_min = media_set_id FROM msdb.dbo.backupset
	WHERE [database_name] = @database AND is_copy_only = 0 AND [type] = 'L' AND backup_start_date < @point_in_time
		AND media_set_id > (SELECT MAX(v) FROM (VALUES (@mediaset_diff),(@mediaset_full)) AS value(v)) ORDER BY backup_start_date ASC;
SET @mediaset_log_min=ISNULL(@mediaset_log_min,'0');
 
--Find mediaset of the latest log backup after the point-in-time and before next full backup
SELECT TOP 1 @mediaset_log_max = media_set_id FROM msdb.dbo.backupset
	WHERE [database_name] = @database AND is_copy_only = 0 AND [type] = 'L' AND backup_start_date > @point_in_time ORDER BY backup_start_date ASC;
 
--If there's no log backup after point-in-time, find the latest log backup before point-in-time
IF @mediaset_log_max IS NULL
	BEGIN
	SELECT TOP 1 @mediaset_log_max = media_set_id FROM msdb.dbo.backupset
		WHERE [database_name] = @database AND is_copy_only = 0 AND [type] = 'L' AND backup_start_date < @point_in_time AND media_set_id > @mediaset_log_min ORDER BY backup_start_date DESC;
	END
SET @mediaset_log_max=ISNULL(@mediaset_log_max,'0');
 
--Find mediasets of the log backups in between
INSERT INTO @logmediaset
SELECT media_set_id FROM msdb.dbo.backupset
	WHERE [database_name] = @database AND is_copy_only = 0 AND [type] = 'L' AND media_set_id >= @mediaset_log_min AND media_set_id < @mediaset_log_max ORDER BY backup_start_date ASC;
 
--Gather names of backup files
INSERT INTO @full_files
SELECT TOP 10 physical_device_name
	FROM msdb.dbo.backupmediafamily WHERE media_set_id = @mediaset_full ORDER BY physical_device_name ASC;
 
INSERT INTO @diff_files
SELECT TOP 10 physical_device_name
	FROM msdb.dbo.backupmediafamily WHERE media_set_id = @mediaset_diff ORDER BY physical_device_name ASC;
 
INSERT INTO @log_files
SELECT TOP 100 physical_device_name, media_set_id
	FROM msdb.dbo.backupmediafamily WHERE media_set_id IN (SELECT media_set_id FROM @logmediaset) ORDER BY media_set_id ASC;
 
--Create info about db files
SELECT @db_file = '';
SELECT @db_file = @db_file+', move '''+[name]+''' to '''+physical_name+'''' FROM sys.master_files WHERE database_id = DB_ID(@database);
SELECT @db_file = RIGHT(@db_file,(LEN(@db_file)-1));
 
--Create info about bak files for restore from full backups
IF (SELECT COUNT (*) FROM @full_files) > 0 BEGIN
	SELECT @full_file = N''
	SELECT @full_file = @full_file+N''', disk='''+physical_device_name FROM @full_files
	SELECT @full_file = LTRIM(RIGHT(@full_file,LEN(@full_file)-2)+'''')
	SELECT @full_file = 'restore database ['+@target_database+'] from '+CHAR(13)+CHAR(10)+REPLACE(@full_file,',',CHAR(13)+CHAR(10)+',')
		+CHAR(13)+CHAR(10)+'with '+CHAR(13)+CHAR(10)+REPLACE(@db_file,',',CHAR(13)+CHAR(10)+',')++CHAR(13)+CHAR(10)+', replace'+CHAR(13)+CHAR(10)+', file=1';
END
--Create info about bak files for restore from diff backups
IF (SELECT COUNT (*) FROM @diff_files) > 0 BEGIN
	SELECT @diff_file = N''
	SELECT @diff_file = @diff_file+N''', disk='''+physical_device_name FROM @diff_files
	SELECT @diff_file = LTRIM(RIGHT(@diff_file,LEN(@diff_file)-2)+'''')
	SELECT @diff_file = 'restore database ['+@target_database+'] from '+CHAR(13)+CHAR(10)+REPLACE(@diff_file,',',CHAR(13)+CHAR(10)+',')
		+CHAR(13)+CHAR(10)+'with replace'+CHAR(13)+CHAR(10)+', file=1';
END
--Create info about bak files for restore from log backups
SELECT @log_file = N'';
SELECT @log_file = @log_file+N'restore log ['+@target_database+N'] from '+CHAR(13)+CHAR(10)+N'disk='''+physical_device_name+''''
	+CHAR(13)+CHAR(10)+N' with replace '+CHAR(13)+CHAR(10)+N', file=1'+CHAR(13)+CHAR(10)+N', norecovery;'+CHAR(13)+CHAR(10)+CHAR(13)+CHAR(10)
	FROM @log_files ORDER BY media_set_id ASC;
 
--Create info about bak files for restore form the last log backup if it's past poin-in-time
IF @point_in_time < (SELECT backup_finish_date FROM msdb.dbo.backupset WHERE media_set_id = @mediaset_log_max)
BEGIN
	SELECT @last_log_file = N'restore log ['+@target_database+'] from '+CHAR(13)+CHAR(10)+N'disk='''+physical_device_name+''''+CHAR(13)+CHAR(10)
		+N' with replace '+CHAR(13)+CHAR(10)+N', file=1'+CHAR(13)+CHAR(10)+N', recovery'+CHAR(13)+CHAR(10)+', stopat='''+CONVERT(varchar,@point_in_time,121)+''';'
		FROM msdb.dbo.backupmediafamily WHERE media_set_id = @mediaset_log_max
	IF @no_recovery = 1 BEGIN SELECT @last_log_file = REPLACE(@last_log_file,'recovery','norecovery'); END
END
ELSE BEGIN
	SELECT @last_log_file = N'restore log ['+@target_database+'] from '+CHAR(13)+CHAR(10)+N'disk='''+physical_device_name+''''+CHAR(13)+CHAR(10)
		+N' with replace '+CHAR(13)+CHAR(10)+N', file=1'+CHAR(13)+CHAR(10)+N', recovery;'
		FROM msdb.dbo.backupmediafamily WHERE media_set_id = @mediaset_log_max
	IF @no_recovery = 1 BEGIN SELECT @last_log_file = REPLACE(@last_log_file,'recovery','norecovery'); END
	SELECT @point_in_time = backup_finish_date FROM msdb.dbo.backupset WHERE media_set_id = @mediaset_log_max;
END
 
--Change information about point-in-time if there is no log to be restored
IF @not_log = 1 OR @last_log_file IS NULL
	BEGIN SELECT @point_in_time = MAX(backup_finish_date) FROM msdb.dbo.backupset WHERE media_set_id IN (@mediaset_diff,@mediaset_full); END
 
--Create powershell script to test if bak files still exist
SELECT @powers1 = '';
SELECT @powers1 = @powers1+ CHAR(13)+CHAR(10)+'Test-Path '''+physical_device_name+'''' FROM @full_files;
SELECT @powers2 = '';
SELECT @powers2 = @powers2+ CHAR(13)+CHAR(10)+'Test-Path '''+physical_device_name+'''' FROM @diff_files;
SELECT @powers3 = '';
SELECT @powers3 = @powers3+ CHAR(13)+CHAR(10)+'Test-Path '''+physical_device_name+'''' FROM @log_files;
SELECT @powers4 = 'Test-Path '''+physical_device_name+'''' FROM msdb.dbo.backupmediafamily WHERE media_set_id = @mediaset_log_max;
 
--Create output
IF @mediaset_full <> 0
BEGIN
	PRINT N'--Script to restore database '+@database+' as '+@target_database;
	PRINT N'-- to a point in time of '+CONVERT(varchar,@point_in_time,121);
	PRINT CHAR(13)+CHAR(10);
	PRINT N'!!!Revise manually the script and verify its correctness';
	PRINT CHAR(13)+CHAR(10);
	PRINT N'--pre restore tasks';
	PRINT N'--run the manual log backup of current DB before overwriting it'
	PRINT N'if exists (select 1 from sys.databases where name='''+@target_database+''' and upper(state_desc)=''ONLINE'')'+
		CHAR(13)+CHAR(10)+'begin alter database ['+@target_database+'] set offline with rollback immediate end;';
	PRINT CHAR(13)+CHAR(10);
	IF @recovery_mod = 'SIMPLE'
		BEGIN PRINT N'Database '+@database+N' has SIMPLE recovery model, recovery to point-in-time is not possible.
		A script using the latest backup before the given point-in-time will be generated instead.'; END
	PRINT N'--restore from full backup'
	+CHAR(13)+CHAR(10)+	@full_file
	IF (@not_log = 1 OR (@mediaset_diff IS NULL AND @mediaset_log_max IS NULL)) AND @no_recovery = 0 BEGIN PRINT ', recovery'; END ELSE BEGIN PRINT N', norecovery;'; END
	PRINT N'go';
	PRINT CHAR(13)+CHAR(10)+CHAR(13)+CHAR(10);
	IF @mediaset_diff IS NOT NULL AND @mediaset_diff <> 0
		BEGIN
		PRINT N'--restore from diff backup' 
		+CHAR(13)+CHAR(10)+@diff_file
		IF @not_log = 1 AND @no_recovery = 0 BEGIN PRINT N', recovery'+CHAR(13)+CHAR(10)+N'go' END ELSE BEGIN PRINT N', norecovery;'+CHAR(13)+CHAR(10)+N'go' END
		PRINT CHAR(13)+CHAR(10)+CHAR(13)+CHAR(10)
		END
	IF @mediaset_log_min IS NOT NULL AND @mediaset_log_max IS NOT NULL AND @not_log = 0 AND @recovery_mod <> 'SIMPLE'
		BEGIN
		PRINT N'--restore from tlog backup(s)'
		+CHAR(13)+CHAR(10)+@log_file+@last_log_file+CHAR(13)+CHAR(10)+N'go'
		PRINT CHAR(13)+CHAR(10)+CHAR(13)+CHAR(10);
		END
	PRINT N'--post restore tasks';
	PRINT N'DBCC CHECKDB ('''+@target_database+''') WITH PHYSICAL_ONLY';
	PRINT CHAR(13)+CHAR(10)+CHAR(13)+CHAR(10);
	PRINT N'/* PowerShell script to verify if the bak files still exist';
	PRINT @powers1;
	PRINT @powers2;
	PRINT @powers3;
	PRINT @powers4;
	PRINT CHAR(13)+CHAR(10)+N'*/';
END
ELSE
BEGIN
	PRINT N'Could not find full backup for database '''+@database+N'''. No script will be generated.'+CHAR(13)+CHAR(10)
	+'Please verify database name and backup history manually.' ;
END
