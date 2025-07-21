--Download main script from https://ola.hallengren.com/downloads.html
--Run it against your default administration DB
 
--Create backup job
exec dbo.DatabaseBackup
	@Databases = 'ALL_DATABASES' -- SYSTEM_DATABASES / USER_DATABASES / ALL_DATABASES / AVAILABILITY_GROUP_DATABASES
	,@Directory = 'C:\Backup'
	,@BackupType = 'FULL' -- FULL / DIFF / LOG
	,@Verify = 'Y' -- N (default) / Y
	,@CleanupTime = 168 -- in hours
	,@CleanupMode = 'AFTER_BACKUP' -- BEFORE_BACKUP / AFTER_BACKUP
	,@Compress = YES --NULL (uses default from sys.configurations) / YES / NO
	,@ChangeBackupType = 'Y' -- N / Y (runs FULL if DIFF/LOG is not possible)
	--,@BackupSoftware = NULL -- NULL (native backup) / DATA_DOMAIN_BOOST / LITESPEED / SQLBACKUP (Red Gate) / SQLSAFE
	,@CheckSum = 'Y' -- N (default) / Y
	,@NumberOfFiles = 4 -- Specifies number of backup files
	,@MinBackupSizeForMultipleFiles = 1024 -- Specifies MB threshold to create multiple backup files
	--,@AvailabilityGroups = 'ALL_AVAILABILITY_GROUPS' -- 'ALL_AVAILABILITY_GROUPS' / 'AG1' / '%AG%'
 
--Create integrity check job
exec dbo.DatabaseIntegrityCheck
	@Databases = 'ALL_DATABASES' -- SYSTEM_DATABASES / USER_DATABASES / ALL_DATABASES / AVAILABILITY_GROUP_DATABASES
	,@CheckCommands = 'CHECKDB' -- CHECKDB / CHECKFILEGROUP / CHECKTABLE / CHECKALLOC / CHECKCATALOG
	,@PhysicalOnly = 'N' -- N / Y
	,@DataPurity = 'N' -- N / Y
	--,@AvailabilityGroups = 'ALL_AVAILABILITY_GROUPS' -- 'ALL_AVAILABILITY_GROUPS' / 'AG1' / '%AG%'
	--,@AvailabilityGroupReplicas = 'ALL' -- PRIMARY / SECONDARY / PREFERRED_BACKUP_REPLICA
 
--Create maintenance job
exec dbo.IndexOptimize
	@Databases = 'ALL_DATABASES' -- SYSTEM_DATABASES / USER_DATABASES / ALL_DATABASES / AVAILABILITY_GROUP_DATABASES
	,@FragmentationLevel1 = 5
	,@FragmentationLevel2 = 30
	,@FragmentationLow = NULL -- NULL / INDEX_REBUILD_ONLINE / INDEX_REBUILD_OFFLINE / INDEX_REORGANIZE / INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE / INDEX_REORGANIZE,INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE
	,@FragmentationMedium = 'INDEX_REORGANIZE,INDEX_REBUILD_ONLINE'
	,@FragmentationHigh = 'INDEX_REBUILD_ONLINE'
	,@UpdateStatistics = 'ALL' -- NULL (default) / INDEX / COLUMNS / NULL
