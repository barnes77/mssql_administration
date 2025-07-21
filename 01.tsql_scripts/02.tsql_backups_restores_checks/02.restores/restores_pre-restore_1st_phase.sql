/*
Created by: Mateusz Wierzbowski
Creation date: 2022/03/17
Aim: Prepare a pre-restore script for all user databases from last full backup during migration
*/
 
USE tempdb;
 
SET NOCOUNT ON;
 
IF OBJECT_ID('#dba_restore_cmd','U') IS NOT NULL BEGIN DROP TABLE #dba_restore_cmd; END
CREATE TABLE #dba_restore_cmd (
	command nvarchar(1000)
);
 
;WITH full_bck_restore_cte AS (
	SELECT
		bs.[database_name] AS [database_name]
		,CAST(bmf.physical_device_name AS varchar(200)) AS physical_device_name
		,ROW_NUMBER() OVER (PARTITION BY bs.[database_name] ORDER BY bs.backup_finish_date DESC) AS row_no
	FROM sys.databases AS sd
	LEFT JOIN msdb.dbo.backupset AS bs ON sd.[name] = bs.[database_name]
	INNER JOIN msdb.dbo.backupmediafamily AS bmf ON bs.media_set_id = bmf.media_set_id
	WHERE 1=1 AND bs.backup_finish_date > DATEADD(DAY, -14, GETDATE())
	AND bs.[database_name] NOT IN ('master','msdb','model','tempdb')
	AND bs.[type] = 'D' AND bs.is_copy_only = 0
),
move_restore_cte AS (
	SELECT
		DB_NAME(database_id) AS [database_name]
		,CONCAT('MOVE ',QUOTENAME([name],''''), ' TO ',QUOTENAME([physical_name],'''')) AS move_cmd
		,ROW_NUMBER() OVER (PARTITION BY database_id ORDER BY [file_id]) AS row_no
	FROM sys.master_files
	WHERE database_id > 4
)
 
INSERT INTO #dba_restore_cmd
SELECT
	CASE
		WHEN mr.row_no = 1 THEN
			CONCAT(CHAR(10),N'RESTORE DATABASE ',QUOTENAME(fbr.[database_name]),' '
				,CHAR(10),'FROM DISK = ',QUOTENAME([physical_device_name],''''),' '
				,CHAR(10),'WITH REPLACE, NORECOVERY'
				,CHAR(10),', ',[move_cmd])
		ELSE CONCAT(', ',[move_cmd])
	END AS [command]
FROM full_bck_restore_cte AS fbr
LEFT JOIN move_restore_cte AS mr ON fbr.[database_name] = mr.[database_name]
WHERE fbr.row_no = 1;
 
DECLARE @restore_cmd nvarchar(1000)
DECLARE cmd_crsr CURSOR LOCAL FAST_FORWARD FOR
SELECT command FROM #dba_restore_cmd
OPEN cmd_crsr;
FETCH NEXT FROM cmd_crsr INTO @restore_cmd
WHILE @@FETCH_STATUS = 0
BEGIN
	PRINT (@restore_cmd)
FETCH NEXT FROM cmd_crsr INTO @restore_cmd;
END
CLOSE cmd_crsr;
DEALLOCATE cmd_crsr;
 
DROP TABLE #dba_restore_cmd;
