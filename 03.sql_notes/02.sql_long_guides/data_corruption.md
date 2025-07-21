**Author:** Mateusz Wierzbowski

**Created:** 2021/02/01

**Revised:** n/a

# Contents

- [Database corruption](#database-corruption)
    - [01. All corruptions that cannot be fixed by repair_rebuild](#all-corruptions-that-cannot-be-fixed-by-repair_rebuild)
    - [02. Severe corruption (the database in 'Suspect' mode)](#severe-corruption-the-database-in-suspect-mode)
    - [03. Less severe data corruption (database still in 'Online' status)](#less-severe-data-corruption-database-still-in-online-status)
- [Log corruption](#log-corruption)
    - [01. How to find a log corruption?](#how-to-find-a-log-corruption)
    - [02. Resolve via switch of recovery model](#resolve-via-switch-of-recovery-model)
    - [03. Resolve via shrink of the log](#resolve-via-shrink-of-the-log)
- [Some general remarks](#some-general-remarks)
    - [01. Monitor disk space](#monitor-disk-space)
    - [02. Finding the last good backup](#finding-the-last-good-backup)


# **Database corruption**

This corruption will be inside data files (.mdf and .ndf) and as such it can be discovered by DBCC CheckDB.

## **All corruptions that cannot be fixed by repair_rebuild**

The best solution is to restore from last known good backup

## **Severe corruption (the database in 'Suspect' mode)**

Please make sure that you don't encounter following scenario: a database joined in AlwaysOn AvailabilityGroup on secondary replica is falling out of synchronization. This can be fixed by

A.  Resuming data movement for the secondary database from SSMS in Object Explorer under AlwaysOn availability

B.  Rejoining (by restoring or seeeding) a secondary database 

C.  If that's not the case, then you will need to reset the database status, put it into 'Emergency' mode, run CheckDB and depending on the result run the correct repair option -- allow data loss will most surely be the option to go

```sql
EXEC sp_resetstatus [YourDatabase];

ALTER DATABASE [YourDatabase] SET EMERGENCY;

--Make sure you save the outcome of the command below in a text file or in a worklog of the ticket (the customer may decide to simply drop corrupted table or index, indexes with ID 2-250 can be simply scripted out and recreated)
--This will include a lowest repair option: repair_rebuild or repair_allow_data_loss
--Contact the DM and customer to get approval for running both options: both of them will require downtime and the former will mean a data loss

DBCC Checkdb([YourDatabase]) WITH NO_INFOMSGS, ALL_ERRORMSGS;

--DATA_PURITY is redundant for DBs created after SQL2000 or older ones for which data_purity has been executed at least once, hence for all DBs with dbi_dbccFlags = 2
--If possible and approved by customer, restore the database from the last known good backup instead of repair_allow_data_loss
--This is the exact command for the fix procedure

ALTER DATABASE [YourDatabase] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

--Consider running all of the statements below in a transaction, so you can easily rollback

--DBCC CheckDB ([YourDatabase], REPAIR_REBUILD); --for less severe errors which do not involve a data loss while fixing
--DBCC CheckDB ([YourDatabase], REPAIR_ALLOW_DATA_LOSS); --for more severe errors which involves a data loss while fixing
--DBCC CheckTable([YourTable], REPAIR_REBUILD); --for less severe errors which do not involve a data loss while fixing, limited to a particular table
--DBCC CheckTable ([YourTable], REPAIR_ALLOW_DATA_LOSS); --for more severe errors which involves a data loss while fixing, limited to a particular table

--If the database is fixed, set it back to multi user

ALTER DATABASE [YourDatabase] SET MULTI_USER;

--Run the CheckDB to be double sure, for relatively smaller DBs you can use option WITH DATA_PURITY

DBCC Checkdb([YourDatabase]) --WITH DATA_PURITY;
```

D.  **Be aware**: Microsoft doesn't recommend a repair_allow_data_loss, the advised solution is <uto restore the database from the last known good backup</u

## **Less severe data corruption (database still in 'Online' status)**

A.  run CheckDB and depending on the result run the correct repair option

```sql
--Make sure you save the outcome of the command below in a text file or in a worklog of the ticket (the customer may decide to simply drop corrupted table or index, indexes with ID 2-250 can be simply scripted out and recreated)
--This will include a lowest repair option: repair_rebuild or repair_allow_data_loss
--Contact the DM and customer to get approval for running both options: both of them will require downtime and the former will mean a data loss

DBCC Checkdb([YourDatabase]) WITH NO_INFOMSGS, ALL_ERRORMSGS;

--DATA_PURITY is redundant for DBs created after SQL2000 or older ones for which data_purity has been executed at least once, hence for all DBs with dbi_dbccFlags = 2
--If possible and approved by customer, restore the database from the last known good backup instead of repair_allow_data_loss
--This is the exact command for the fix procedure

ALTER DATABASE [YourDatabase] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

--Consider running all of the statements below in a transaction, so you can easily rollback
--DBCC CheckDB ([YourDatabase], REPAIR_REBUILD); --for less severe errors which do not involve a data loss while fixing
--DBCC CheckDB ([YourDatabase], REPAIR_ALLOW_DATA_LOSS); --for more severe errors which involves a data loss while fixing
--DBCC CheckTable([YourTable], REPAIR_REBUILD); --for less severe errors which do not involve a data loss while fixing, limited to a particular table
--DBCC CheckTable ([YourTable], REPAIR_ALLOW_DATA_LOSS); --for more severe errors which involves a data loss while fixing, limited to a particular table

--If the database is fixed, set it back to multi user

ALTER DATABASE [YourDatabase] SET MULTI_USER;

--Run the CheckDB to be double sure, for relatively smaller DBs you can use option WITH DATA_PURITY

DBCC Checkdb([YourDatabase]) --WITH DATA_PURITY;
```

B.  **Be aware**: Microsoft doesn't recommend a repair_allow_data_loss, the advised solution is <uto restore the database from the last known good backup</u

# **Log corruption**

This is a corruption of .ldf file and as such won't be discovered by CheckDBs, you will get the errors in SQL Server logs when it is discovered during a log backup. Since the CheckDBs won't be able to discover this kind of corruption, it also cannot fix that type of error

## **How to find a log corruption?**

```sql
--Look for suspect_pages 
SELECT DB_NAME(database_id), file_id, page_id, event_type,error_count,last_update_date 
FROM msdb.dbo.suspect_pages 
--Look for damaged backups 
SELECT database_name,backup_start_date,backup_finish_date,is_damaged 
FROM msdb.dbo.backupset 
WHERE is_damaged = 1 
ORDER BY backup_start_date DESC 
```

The best advice is to restore database from the last known good backup, but it needs to be approved by DM and customer, since it involves a data loss

## **Resolve via switch of recovery model**

```sql
--Ask management and customer to approve this approach
--Ask customer to stop the application
--Alternatively disable on SQL server logins accessing the database
--Run full backup of the database manually
--Change the recovery model to simple

USE [master]
ALTER DATABASE [YourDatabase] SET RECOVERY SIMPLE WITH NO_WAIT

--Shrink the log afterwards

USE [YourDatabase]
DBCC SHRINKFILE (YourDatabaseLog,0);

--Verify that there are only default VLFs in the log, i.e. if all VLFs have CreateLSN = 0

DBCC loginfo ('YourDatabase')

--Change the recovery model to full

USE [master]
ALTER DATABASE [YourDatabase] SET RECOVERY FULL WITH NO_WAIT

--Rebuild the log - set it to a reasonable size, e.g. the size from before the repair or 2000 MB for growth 100 MB, 4000 MB for growth 250 MB or 8000 MB for growth 500 MB 
--Run full backup of the database manually
```

## **Resolve via shrink of the log**

```sql
--Ask management and customer to approve this approach
--Ask customer to stop the application
--Alternatively disable on SQL server logins accessing the database
--Run diff backup of the database manually, to be able to rollback the actions afterwards
--Run checkpoint on the database

USE [YourDatabase]
CHECKPOINT;

--Execute manually log backup with continue_after_error option (this can be done via advanced options in CV as well) and shrink the log afterwards

--Repeat the steps until the log is shrunk to 0 MB preferably
--This is done in order to shrink the log past the corruption point

BACKUP log YourDatabase TO DISK = 'filepathyourdatabase_yyyyMMdd_hhmmss_log.trn'
WITH CONTINUE_AFTER_ERROR;

USE [YourDatabase]
DBCC SHRINKFILE (YourDatabaseLog,0);

--Verify that there are only default VLFs in the log, i.e. if all VLFs have CreateLSN = 0

DBCC LOGINFO ('YourDatabase')

--If the log is shrunk completely, run the standard log backup job or standard log backup from CV

--If the log backup job completes successfully, rebuild the log - set it to a reasonable size, e.g. the size from before the repair or 2000 MB for growth 100 MB, 4000 MB for growth 250 MB or 8000 MB for growth 500 MB
```

# **Some general remarks**

## **Monitor disk space**

In case of running repairs it's crucial that tempdb has enough space to expand both data and log files, especially in case of large databases. You can also encounter the issue with space for growth of the repaired database's log -- make sure to monitor it during the CheckDB and shrink other big log files there or expand the drive in advance.

## **Finding the last good backup** 

You need to cross check the history of the affected database and find the last backup that finished before the first occurrence of corruption errors, these you can find with below query:

```sql
DECLARE @Archive INT;

IF OBJECT_ID('#dba_enumerrorlogs') IS NOT NULL DROP TABLE [#dba_enumerrorlogs];

CREATE TABLE [#dba_enumerrorlogs] ([Archive] INT,[Date] DATETIME,[Log File Size (Byte)] INT)

IF OBJECT_ID('#dba_readerrorlog') IS NOT NULL DROP TABLE [#dba_readerrorlog];

CREATE TABLE [#dba_readerrorlog] ([LogDate] DATETIME,[ProcessInfo] VARCHAR(50),[Text] VARCHAR(4000))

INSERT INTO [#dba_enumerrorlogs] EXEC [sys].[xp_enumerrorlogs];

DECLARE cur_enumerrorlogs CURSOR FOR SELECT [Archive] FROM [#dba_enumerrorlogs] ORDER BY [Archive] DESC;

OPEN cur_enumerrorlogs; FETCH NEXT FROM cur_enumerrorlogs INTO @Archive;

WHILE @@FETCH_STATUS = 0

BEGIN 
INSERT INTO [#dba_readerrorlog] EXEC sys.xp_readerrorlog @Archive;
FETCH NEXT FROM cur_enumerrorlogs INTO @Archive;
END

CLOSE cur_enumerrorlogs;
DEALLOCATE cur_enumerrorlogs;

SELECT * FROM [#dba_readerrorlog]

--Log corruption: Use below condition and change YourDatabase to actual database name
--WHERE LOWER([Text]) LIKE '%log%corruption%YourDatabase%'

--Database corruption: Use below condition and change YourDatabase to actual database name
WHERE LOWER([Text]) LIKE '%YourDatabase%checkdb%errors%' 
AND LOWER([Text]) NOT LIKE '%found 0 errors%' 
AND LOWER([Text]) NOT LIKE '%without errors%'

ORDER BY [LogDate] DESC;
DROP TABLE [#dba_readerrorlog];
DROP TABLE [#dba_enumerrorlogs];
```
