
SET NOCOUNT ON;
 
SELECT
	CONVERT(CHAR(100),SERVERPROPERTY('Servername')) AS server_name
	,bs.[database_name]
	,MAX(bs.backup_finish_date) AS last_db_backup_date
	,DATEDIFF(hh, MAX(bs.backup_finish_date),GETDATE()) AS backup_age_hours
FROM sys.databases AS sdb
LEFT JOIN msdb.dbo.backupset AS bs ON sdb.[name] = bs.[database_name]
WHERE bs.type = 'D'
GROUP BY bs.[database_name]
HAVING (MAX(bs.[backup_finish_date]) < DATEADD(hh,-24,GETDATE()))
UNION
--Databases without any backup history
SELECT	
	CONVERT(CHAR(100),SERVERPROPERTY('Servername')) AS server_name
	,sdb.[name] AS [database_name]
	,NULL AS last_db_backup_date
	,NULL AS backup_age_hours
FROM sys.databases AS sdb
LEFT JOIN msdb.dbo.backupset AS bs ON sdb.[name] = bs.[database_name]
WHERE 1=1
	AND bs.[database_name] IS NULL 
	AND sdb.[name] <> 'tempdb'
ORDER BY bs.[database_name] ;
