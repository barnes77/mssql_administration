**Author:** Mateusz Wierzbowski

**Created:** 2021/02/01

**Revised:** 2022/03/22

# Contents

- [**General considerations**](#general-considerations)
- [**Scenarios**](#scenarios)
- [**Preliminary considerations:**](#preliminary-considerations)
    - [**All scenarios**](#all-scenarios)
- [**Pre-Implementation steps on the source**](#pre-implementation-steps-on-the-source)
    - [**All scenarios**](#all-scenarios-1)
- [**Pre-Implementation steps on the target:**](#pre-implementation-steps-on-the-target)
    - [**Scenario A** (source is a new instance with new name and IP)](#scenario-a-source-is-a-new-instance-with-new-name-and-ip)
    - [**Scenario B** (source is a new instance with new name and IP, migration done via HA solutions)](#scenario-b-source-is-a-new-instance-with-new-name-and-ip-migration-done-via-ha-solutions)
    - [**Scenario C** (side-by-side migration)](#scenario-c-side-by-side-migration)
    - [**Scenario D** (target is the source after fresh install of OS)](#scenario-d-target-is-the-source-after-fresh-install-of-os)
- [**Implementation steps:**](#implementation-steps)
    - [**All scenarios:**](#all-scenarios-2)
    - [**Scenario A** (source is a new instance with new name and IP)](#scenario-a-source-is-a-new-instance-with-new-name-and-ip-1)
    - [**Scenario B** (source is a new instance with new name and IP, migration done via HA solutions)](#scenario-b-source-is-a-new-instance-with-new-name-and-ip-migration-done-via-ha-solutions-1)
    - [**Scenario C** (side-by-side migration)](#scenario-c-side-by-side-migration-1)
    - [**Scenario D** (target is the source after fresh install of OS)](#scenario-d-target-is-the-source-after-fresh-install-of-os-1)
- [**Post-Implementation steps:**](#post-implementation-steps)
    - [**Scenario A** (source is a new instance with new name and IP)](#scenario-a-source-is-a-new-instance-with-new-name-and-ip-2)
    - [**Scenario B** (source is a new instance with new name and IP,migration done via HA solutions)](#scenario-b-source-is-a-new-instance-with-new-name-and-ip-migration-done-via-ha-solutions-2)
    - [**Scenario C** (side-by-side migration)](#scenario-c-side-by-side-migration-2)
    - [**Scenario D** (target is the source after fresh install of OS)](#scenario-d-target-is-the-source-after-fresh-install-of-os-2)
- [**Rollback steps**](#rollback-steps)
    - [**Scenario A** (source is a new instance with new name and IP)](#scenario-a-source-is-a-new-instance-with-new-name-and-ip-3)
    - [**Scenario B** (source is a new instance with new name and IP,migration done via HA solutions)](#scenario-b-source-is-a-new-instance-with-new-name-and-ip-migration-done-via-ha-solutions-3)
    - [**Scenario C** (side-by-side migration)](#scenario-c-side-by-side-migration-3)
    - [**Scenario D** (target is the source after fresh install of OS)](#scenario-d-target-is-the-source-after-fresh-install-of-os-3)
- [**Migration of additional features:**](#migration-of-additional-features)
    - [**SSIS**](#ssis)
        - [**Scenario A** (backup & restore)](#scenario-a-backup-restore)
        - [**Scenario B** (Deploy a project from Visual Studio Integration Services Project)](#scenario-b-deploy-a-project-from-visual-studio-integration-services-project)
    - [**SSRS**](#ssrs)
        - [**Scenario A** (backup & restore)](#scenario-a-backup-restore-1)
    - [**SSAS**](#ssas)
        - [**Scenario A** (backup & restore)](#scenario-a-backup-restore-2)
- [**Further reading:**](#further-reading)


# **General considerations**

<u>!!!Important Note!!!</u> Migration of SSIS/SSRS/SSAS is discussed separately at the end of this guide in more details, in the
scenarios A-D, there's only one way of handling the migration, i.e. via backup & restore

# Scenarios

1. **scenario A** - Migration of SQL to a new server under new host/server/instance name with new IP address; great - limited downtime, easy fail back to the old SQL instance

2. **scenario B** - Migration of SQL to a new server under new host/server/instance name with new IP address via HA solutions (AlwaysOn, Mirroring, LogShipping); good - limited downtime, easy fail back to the old SQL instance, time-consuming setting up HA solution - once new server becomes primary in HA,Mirroring,LogShipping no way to switch back to the old instance

3. **scenario C** - Migration of SQL to a new parallel SQL instance on the same host; bad - more problematic configuration, easy failback

4. **scenario D** - Migration of SQL to a new SQL instance on the old host after fresh install of OS; very bad, no fail back except for a bare metal restore

# Preliminary considerations

## **All scenarios**

01. Verify which applications are using the databases and agree their shutdown for the time of migration

02. If migrating to a new separate host, verify the new host configuration

* if the new OS Version is suitable for the planned SQL version

| **SQL Server** | **Win 2003 R2** | **Win 2008 R2** | **Win 2012** | **Win 2012 R2** | **Win 2016** | **Win 2019** | **Win 2022** |
| ------ | ------ | ------ | ------ | ------ | ------ | ------ | ------ |
| | **Standalone / Cluster** | **Standalone / Cluster** | **Standalone / Cluster** | **Standalone / Cluster** | **Standalone / Cluster** | **Standalone / Cluster** | **Standalone / Cluster** |
| **SQL 2000** | ok / no | no | no | no | no | no | no |
| **SQL 2005** | ok | ok | no | no | no | no | no |
| **SQL 2008** | no | ok | ok | ok | no | no | no |
| **SQL 2008 R2** | no | ok | ok | ok | no | no | no |
| **SQL 2012** | no | ok | RTM no (SP4+ ok) | RTM no (SP4+ ok) | RTM no (SP4+ ok) | RTM no (SP4+ ok) | no |
| **SQL 2014** | no | no | RTM no (SP3+ ok) | RTM no (SP3+ ok) | RTM no (SP3+ ok) | RTM no (SP3+ ok) | no |
| **SQL 2016** | no | no | RTM no (SP2+ ok) | RTM no (SP2+ ok) | RTM no (SP2+ ok) | RTM no (SP2+ ok) | no |
| **SQL 2017** | no | no | ok | ok | ok | ok | ok |
| **SQL 2019** | no | no | no | no | ok | ok | ok |

Source: https://docs.microsoft.com/en-us/troubleshoot/sql/general/use-sql-server-in-windows

* if there's enough disk space, you can use PowerShell script for that

    ```powershell
    Get-WmiObject -Class Win32_LogicalDisk| ForEach-Object { "Drive: "+$_.DeviceID+"`t`t`tSize: "+( [math]::Round( ($_.Size/1GB),2 ) )+" GB`t`t`t`tFree Space: "+( [math]::Round( ($_.FreeSpace/1GB),2 ) )+" GB" }
    ```

* if there's enough RAM, you can use PowerShell script for that

    ```powershell
    Get-WmiObject -Class Win32_ComputerSystem| Foreach { "RAM info: `r`nPhysical Memory: "+( [math]::Round( ($_.TotalPhysicalMemory/1GB) ,0) )+" GB" }
    ```

* if there's enough of CPU cores, you can use PowerShell script for that

    ```powershell
    Get-WmiObject -Class Win32_ComputerSystem| Measure NumberOfProcessors -Sum| Select Sum | %{"NumberOfProcessors: "+$_.Sum}
    Get-WmiObject -Class Win32_Processor| Measure NumberOfLogicalProcessors -Sum| Select Sum | %{"NumberOfLogicalProcessors: "+$_.Sum}
    Get-WmiObject -Class Win32_Processor| Measure NumberOfCores -Sum| Select Sum | %{"NumberOfCores: "+$_.Sum}
    Get-WmiObject -Class Win32_Processor| Measure CurrentClockSpeed -Average| Select Average | %{"CurrentClockSpeed: "+([math]::Round( ( $_.Average / 1000) ,2) ) +" GHz"}
    ```

03. Get passwords for the existing service accounts, if applicable, otherwise request new service accounts

04. If migrating to a new server, perform a fresh installation of SQL server with correct version and edition

* If migrating to a new server via HA solution, perform a fresh installation of SQL server with correct version and edition and configure appropriate HA solution

05. Be aware that Synonyms on other instances pointing to the current instance in case of scenarios A1 and A2 will fail and there's no technical possibility to query synonyms on all other instances - this needs to be addressed by application team

06. Verify if there are any encrypted databases on the server by querying encryption keys and agree with the team how it should be approached.

    > Note: Older encryption algorithms (DES, Triple DES, TRIPLE_DES_3KEY, RC2, RC4, 128-bit RC4, and DESX) are allowed in SQL2016+ only in case of databases with compatibility up to 120

    > Note: In case of TDE most probably you will need to physically move encryption keys and database files between servers (detach, attach) or drop the encryption in advance

    ```sql
    SELECT
        DB_NAME(database_id) AS DBName
        ,key_algorithm
        ,key_length
        ,encryptor_type
        ,percent_complete
        ,create_date
        ,regenerate_date
        ,modify_date
        ,opened_date
    FROM sys.dm_database_encryption_keys
    ```

07. Verify if the source target does use unsafe/external assemblies and consult with the app team how to approach it. Basically, app team needs to provide a signed CLR or issue a warning that the strict security will have to be disabled on the target server (this is a new feature in SQL 2017). To find such assemblies run following command on source server

```sql
SELECT * FROM sys.assemblies
WHERE permission_set_desc IN ('EXTERNAL_ACCESS','UNSAFE_ACCESS') --Remove this clause to include safe assemblies as well
```

08. Make sure that the app team understands that they might be using deprecated features that won't be supported in the new SQL installation. You can get an overview of this running following script on the source server

```sql
SELECT object_name, instance_name AS deprecated_feature, cntr_value
FROM sys.dm_os_performance_counters
WHERE object_name LIKE '%Deprecated%' AND cntr_value > 0
ORDER BY cntr_value DESC
```

> **Features deprecated:**  
> SQL2017-2019 [https://docs.microsoft.com/en-us/sql/database-engine/deprecated-database-engine-features-in-sql-server-2016?view=sql-server-ver1](https://docs.microsoft.com/en-us/sql/database-engine/deprecated-database-engine-features-in-sql-server-2016?view=sql-server-ver1)  
> SQL 2005 [https://docs.microsoft.com/en-us/previous-versions/sql/sql-server-2005/ms144262(v=sql.90)?redirectedfrom=MSDN](https://docs.microsoft.com/en-us/previous-versions/sql/sql-server-2005/ms144262(v=sql.90)?redirectedfrom=MSDN)

09. Verify if new SPNs will be required on the new instance (in case of using Kerberos authentication)

10. Ask app team if there's anything that you should know which is specific in the instance, pay attention to:
* Any kind of share on FS that can be used by SSIS/Agent jobs etc. and permissions set for it
* Providers/Drivers used by SSIS packages that don't come with the standard SQL installation
* Make sure to discuss how SSIS/SSRS/SSAS databases will be approached and regarding to SSIS/SSAS will application team assist with deployments from Visual Studio
* Ask if the application is using default  [sa] account, if yes - you should ask them to use a new login on the new instance or set the same password for the default  [sa]

# **Pre-Implementation steps on the source**

## **All scenarios**

01. List configuration options and traceflags

```sql
SELECT * FROM sys.configurations
DBCC TRACESTATUS(-1);
```

02. List all databases with some basic options;

> Note: pay attention to these having isolation level set to Read Committed Snapshot and is_trustworthy (these values are kept in msdb and won't be inherited by a restored database);

> Note: SQL Servers 2014-2019 have the lowest compatibility level of 100, all databases with lower compatibility on the source will have it set to 100 after the restore by default;

```sql
SELECT
	database_id as [dbid]
	,[name] as 'DBName'
	,SUSER_SNAME(owner_sid) AS [Owner]
	,state_desc
	,recovery_model_desc
	,collation_name
	,user_access_desc
	,[compatibility_level]
	,is_read_only
	,is_read_committed_snapshot_on
	,is_broker_enabled
	,is_auto_close_on
	,is_auto_shrink_on
	,is_auto_create_stats_on
	,is_auto_update_stats_on
	,is_fulltext_enabled
	,is_trustworthy_on
	,is_master_key_encrypted_by_server
	,is_encrypted
FROM sys.databases
```

03.  Script out all logins except for NT AUTHORITY/NT SERVICE/default sa

> Note: database permissions are held inside each database, so they will be migrated during restores of the databases, for systemdbs specific roles see next point

> Note: if for some reason default [sa] is used use this command to generate a query to alter [sa] on the new instance with hashed password from the source instance

```sql
SELECT
	N'CREATE LOGIN ['+sp.[name]+'] WITH PASSWORD=0x'+CONVERT(nvarchar(max), l.password_hash, 2)+N' HASHED,
	SID=0x'+CONVERT(nvarchar(max), sp.[sid], 2)+', DEFAULT_DATABASE=['
	+sp.default_database_name+'], DEFAULT_LANGUAGE=['+sp.default_language_name+'], CHECK_EXPIRATION='+CASE
	WHEN l.is_policy_checked = 1 THEN 'ON' ELSE 'OFF' END
	+', CHECK_POLICY='+CASE WHEN l.is_policy_checked = 1 THEN 'ON' ELSE 'OFF' END+';'
	+CASE WHEN sp.is_disabled = 1 THEN ' ALTER LOGIN ['+sp.[name]+'] DISABLE' ELSE '' END
FROM master.sys.server_principals AS sp
INNER JOIN master.sys.sql_logins AS l ON sp.[sid]=l.[sid]
WHERE sp.[type]='S' AND sp.[name] NOT LIKE '##%' AND sp.[sid] <> 0x01 --AND sp.is_disabled = 0 --use this condition to exclude disabled logins
UNION ALL
	SELECT
	N'CREATE LOGIN ['+sp.[name]+'] FROM WINDOWS WITH DEFAULT_DATABASE=['+sp.default_database_name+'],
	DEFAULT_LANGUAGE=['+sp.default_language_name+'];'
	+CASE WHEN sp.is_disabled = 1 THEN ' ALTER LOGIN ['+sp.[name]+'] DISABLE' ELSE '' END
FROM master.sys.server_principals AS sp
WHERE (sp.[type]='U' OR sp.[type]='G') AND sp.[name] NOT LIKE 'NT %' --AND sp.is_disabled = 0 --use this condition to exclude disabled logins
UNION ALL
SELECT
	'ALTER SERVER ROLE ['+sp2.[name]+'] ADD MEMBER ['+sp.[name]+'];'
FROM master.sys.server_principals AS sp
LEFT JOIN sys.server_role_members AS sdrm ON sp.principal_id = sdrm.member_principal_id
LEFT JOIN sys.server_principals AS sp2 ON sp2.principal_id = sdrm.role_principal_id
WHERE (sp.[type]='U' OR sp.[type]='G' OR sp.[type]='S') AND sp.[name] NOT LIKE 'NT %' AND sp.[name] NOT LIKE '##%'
AND sp.[sid] <> 0x01 AND sp2.[name] IS NOT NULL
```

04. Script out SQL Jobs - in SSMS while being in a tab for SQL Agent jobs, press F7 to go to Object Explorer Details, mark all jobs and right click and script them out

05. Script out SQL Operators - in SSMS while being in a tab for SQL Agent operators, press F7 to go to Object Explorer Details, mark all operators and right click and script them out

06. Script out Alerts - in SSMS while being in a tab for SQL Agent alerts, press F7 to go to Object Explorer Details, mark all alerts and right click and script them out

07. Script out Triggers - in SSMS while being in a tab for Server Object Triggers, press F7 to go to Object Explorer Details, mark all triggers and right click and script them out

08. Script out Database Mail

> Note: it doesn't include passwords for password protected profiles, these should be delivered by app team or new passwords can be set on the target

> Use a query by Frank Gill: https://github.com/skreebydba/skreebydbablog/blob/main/MigrateDbMailSettings.sql

09. Script out Linked Servers - in SSMS while being in a tab for Linked Servers, press F7 to go to Object Explorer Details, mark all Linked Servers and right click and script them out;

> Note: this will not include passwords for Linked Servers - you can use a script by Antti Rantasaari published by Richard Swinbank to get them : https://www.richardswinbank.net/admin/extract_linked_server_passwords

10. Script out user permissions inside system databases (master, msdb)

```sql
USE [master]
SELECT 'ALTER ROLE ['+sdp2.[name]+'] ADD MEMBER ['+sdp.[name]+'];'
FROM sys.database_principals AS sdp
LEFT JOIN sys.database_role_members AS sdrm ON sdp.principal_id = sdrm.member_principal_id
LEFT JOIN sys.database_principals AS sdp2 ON sdp2.principal_id = sdrm.role_principal_id
WHERE sdp.[type] IN ('S','G','U') AND sdp.[name] NOT LIKE '%MS_%'
AND sdp2.[type] = 'R' AND (sdp2.principal_id BETWEEN 0 AND 16000)

USE [msdb]
SELECT 'ALTER ROLE ['+sdp2.[name]+'] ADD MEMBER ['+sdp.[name]+'];'
FROM sys.database_principals AS sdp
LEFT JOIN sys.database_role_members AS sdrm ON sdp.principal_id = sdrm.member_principal_id
LEFT JOIN sys.database_principals AS sdp2 ON sdp2.principal_id = sdrm.role_principal_id
WHERE sdp.[type] IN ('S','G','U') AND sdp.[name] NOT LIKE '%MS_%'
AND sdp2.[type] = 'R' AND (sdp2.principal_id BETWEEN 0 AND 16000)
```

11. Script out Log Shipping configuration for each database, go to properties of the database and to tab Transaction Log Shipping, then choose Script Configuration

> Note: Please note that the script will consist of parts that need to be run against different members of Log Shipping setup: primary, secondary and witness

12. Create a backup of Service Master Key just in case and store in either on target server or on another server not participating in migration

```sql
BACKUP SERVICE MASTER KEY TO FILE = 'folder\instance_smk.key' ENCRYPTION BY PASSWORD = 'xxx' --run at old instance
```

13. (Backup) Create a backup of Database Master Key for each database that is using Master Key, you can verify these databases by running following command

```sql
USE tempdb
CREATE TABLE #symmetric_keys (
	[db_name] sysname, name sysname, principal_id int, symmetric_key_id int, key_length int, key_algorithm
char(2), algorithm_desc nvarchar(60),
	create_date datetime, modify_date datetime, key_guid uniqueidentifier, key_thumbprint sql_variant,
provider_type nvarchar(120),
	cryptographic_provider_guid uniqueidentifier, cryptographic_provider_algid sql_variant
)
EXEC sp_MSforeachdb
'USE [?]
INSERT INTO #symmetric_keys
SELECT DB_NAME() AS DB,*
FROM sys.symmetric_keys'
SELECT * FROM #symmetric_keys
DROP TABLE #symmetric_keys

-- USE [database]
-- BACKUP MASTER KEY TO FILE = 'folder\db.key' ENCRYPTION BY PASSWORD = 'xxx' --run at old instance
```

14. (SSISDB via backup & restore) Check if you have the password used for creation of Integration Service Catalog (Master Key). If you don't have it, you can either simply take a backup of current Master Key (see step above), if you have it, still it's reasonable to take this backup as well

15. (SSISDB via backup & restore) Perform following points:
* Script out login ##MS_SSISServerCleanupJobLogin##
* Script out procedure master.dbo.sp_ssis_startup
* Script out Agent job \[SSIS Server Maintenance Job\]
* Export each project from Integration Service Catalog (.ispac file)
* Script out logins in SSISDB

```sql
SET NOCOUNT ON;
SELECT
 dbpri.[name] AS [login]
 ,dbpri2.[name] AS [db_role]
FROM sys.database_principalsASdbpri
LEFT JOIN sys.database_role_membersASdbrm ON dbpri.principal_id = dbrm.member_principal_id
LEFT JOIN sys.database_principalsASdbpri2 ON dbpri2.principal_id = dbrm.role_principal_id
WHERE 1=1
AND dbpri.type <> 'R'
AND dbpri.name NOT IN ('dbo','sys','guest','INFORMATION_SCHEMA','AllSchemaOwner','ModuleSigner','MS_DataCollectorInternalUser')
AND dbpri.name NOT LIKE '##%'
```

16. (SSRS via backup & restore) Perform following points
* In Reporting Services Configuration Manager on the source instance, check Database tab and verify if the SSRS is using default DBs, i.e. ReportServer and ReportServerTempDB, if not, then use the non-default names in the next steps
* In Reporting Services Configuration Manager on the source instance, open Encryption Keys, take a backup protected by strong password
* Take a screenshot of all configurations in Reporting Services Configuration Manager, i.e. tabs Servie Account, Web Service URL, Database, Rerport Server Database etc.
* Take full backup of ReportServer and ReportServerTempDB
* Script out databas role RSExecRole and its schema both from master <u>and</u> msdb

```sql
USE [master]
SET NOCOUNT ON;
SELECT
 dbpri.[name] AS [login]
 ,dbpri2.[name] AS [db_role]
FROM sys.database_principals AS dbpri
LEFT JOIN sys.database_role_members AS dbrm ON dbpri.principal_id = dbrm.member_principal_id
LEFT JOIN sys.database_principals AS dbpri2 ON dbpri2.principal_id = dbrm.role_principal_id
WHERE 1=1
AND dbpri.type <> 'R'
AND dbpri.name NOT IN ('dbo','sys','guest','INFORMATION_SCHEMA','AllSchemaOwner','ModuleSigner','MS_DataCollectorInternalUser')
AND dbpri.name NOT LIKE'##%'

USE [msdb]
SET NOCOUNT ON;
SELECT
 dbpri.[name] AS [login]
 ,dbpri2.[name] AS [db_role]
FROM sys.database_principals AS dbpri
LEFT JOIN sys.database_role_members AS dbrm ON dbpri.principal_id = dbrm.member_principal_id
LEFT JOIN sys.database_principals AS dbpri2 ON dbpri2.principal_id = dbrm.role_principal_id
WHERE 1=1
AND dbpri.type <> 'R'
AND dbpri.name NOT IN ('dbo','sys','guest','INFORMATION_SCHEMA','AllSchemaOwner','ModuleSigner','MS_DataCollectorInternalUser')
AND dbpri.name NOT LIKE'##%'
```

* Make a copy following files RSReportServer.config and RSWebApplication.config

# **Pre-Implementation steps on the target**

## **Scenario A** (source is a new instance with new name and IP)

01. Verify that the new instance is up. Cross check configuration between source and target, pay attention to following values: CTP, Max DOP, min and max server memory, AdHoc Distributed Queries, User connections, Remote access, Remote Login timeout, CLR, Backup Compression; Enable traceflags as they were configured on the source (verify if all of them are applicable for new version of SQL, e.g. 1117,1118,2371)

02. On the source take the last scheduled full backup before the migration and restore it on the target with norecovery;

> Note: this is not applicable for TDE encrypted > databases;

> Note: if you use native SQL backups you can use this script on the source to generate pre-restore script (CHANGE FILEPATHS
FOR PHYSICAL FILES)

```sql
--Perform on AUVSQLWNGP04\WIND_DB, copy the result, remove last line ("Completion time..."), execute against LCVSQLWNGP04\WIND_DB,1433, wait for execution (approx. 3 hours)
--SCRIPT FOR FULL RESTORE DURING PRE-RESTORE PHASE
USE tempdb;
SET NOCOUNT ON;
IF OBJECT_ID('#dba_restore_cmd','U') IS NOT NULL BEGIN DROP TABLE #dba_restore_cmd END;
CREATE TABLE #dba_restore_cmd (
	command nvarchar(1000)
	,row_no int identity(1,1)
)
;WITH full_bck_restore_cte AS (
	SELECT
		bs.[database_name] AS [database_name]
		,CAST(bmf.physical_device_name AS varchar(200)) AS physical_device_name
		,ROW_NUMBER() OVER (PARTITION BY bs.[database_name] ORDER BY bs.backup_finish_date DESC) AS row_no
	FROM msdb.dbo.backupset AS bs
	INNER JOIN msdb.dbo.backupmediafamily AS bmf ON bs.media_set_id = bmf.media_set_id
	WHERE 1=1 AND bs.backup_finish_date > DATEADD(DAY, -14, GETDATE()) AND bs.[database_name] NOT IN ('master','msdb','model','tempdb') 
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
	WHEN mr.row_no = 1 THEN CONCAT(CHAR(10),N'RESTORE DATABASE ',QUOTENAME(fbr.[database_name]),' '
			,CHAR(10),'FROM DISK = ',QUOTENAME([physical_device_name],''''),' '
			,CHAR(10),'WITH REPLACE, NORECOVERY'
			,CHAR(10),', ',[move_cmd])
		ELSE CONCAT(', ',[move_cmd])
	END AS [command]
FROM full_bck_restore_cte AS fbr
LEFT JOIN move_restore_cte AS mr ON fbr.[database_name] = mr.[database_name]
WHERE fbr.row_no = 1

DECLARE @restore_cmd nvarchar(1000)
DECLARE cmd_crsr CURSOR LOCAL FAST_FORWARD FOR
SELECT command FROM #dba_restore_cmd ORDER BY row_no ASC
OPEN cmd_crsr;
FETCH NEXT FROM cmd_crsr INTO @restore_cmd
WHILE @@FETCH_STATUS = 0
BEGIN
	PRINT (@restore_cmd)
FETCH NEXT FROM cmd_crsr INTO @restore_cmd
END;
CLOSE cmd_crsr;
DEALLOCATE cmd_crsr;
DROP TABLE #dba_restore_cmd;
```

03. On the target recreate logins scripted out already on the source, optionally alter [sa] with hashed password from the old instance

04. On the target recreate Agent operators scripted out already on the source

05. On the target recreate Agent jobs scripted out already on the source;

> Note: if the job_owner is not present on the target yet, job creation will fail;
> Note: keep them disabled until final steps of the > migration

06. On the target recreate Alerts scripted out already on the source

07. On the target recreate Triggers scripted out already on the source

08. On the target configure DBMail and recreate DBMail Profiles scripted out already on the source;

> Note: You need to change the password manually, ask app team for the old ones or set new ones

09. On the target recreate LinkedServers, remember to update the passwords

10. On the target recreate database permissions inside msdb and master

11. Verify if the steps above have been successful

12. Ask another team member (preferably) or check yourself if the following configs seem to be right

```sql
SET NOCOUNT ON;
DECLARE @sql_data_root varchar(256), @back_path sql_variant

EXEC [master].dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',N'SOFTWARE\Microsoft\MSSQLServer\Setup',N'SQLDataRoot',@sql_data_root output

IF SERVERPROPERTY('ProductMajorVersion') >= 1
	BEGIN
		SELECT @back_path = SERVERPROPERTY('InstanceDefaultBackupPath')
	END
ELSE
	BEGIN
		EXEC [master].dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',N'SOFTWARE\Microsoft\MSSQLServer\MSSQLServer', N'BackupDirectory',@back_path output
	END

SELECT
	@@SERVERNAME AS server_name
	,SERVERPROPERTY('ProductVersion') AS [version]
	,(SELECT service_account FROM sys.dm_server_services WHERE LOWER(servicename) LIKE '%sql server%' AND LOWER(servicename) NOT LIKE '%agent%') AS sql_svc_acc
	,(SELECT service_account FROM sys.dm_server_services WHERE LOWER(servicename) LIKE '%agent%') AS agent_svc_acc
	,SERVERPROPERTY('Edition') AS [edition]
	,CASE
		WHEN SERVERPROPERTY('IsIntegratedSecurityOnly') = 0 THEN 'Mixed Mode Authentication'
		ELSE 'Windows Mode Authentication'
	END AS [authentication]
	,SERVERPROPERTY('Collation') AS collation
	,@sql_data_root AS data_root_dir
	,SERVERPROPERTY('InstanceDefaultDataPath') AS def_data_path
	,SERVERPROPERTY('InstanceDefaultLogPath') AS def_log_path
	,@back_path AS def_backup_path;
```

## **Scenario B** (source is a new instance with new name and IP, migration done via HA solutions)

01. Verify that the new instance is up. Cross check configuration between source and target, pay attention to following values: CTP, Max DOP, min and max server memory, AdHoc Distributed Queries, User connections, Remote access, Remote Login timeout, CLR, Backup Compression; Enable traceflags as they were configured on the source (verify if all of them are applicable for new version of SQL, e.g. 1117,1118,2371)

02. Configure HA solution accordingly

03. On the target recreate logins scripted out already on the source, optionally alter [sa] with hashed password from the old instance

04. On the target recreate Agent operators scripted out already on the source

05. On the target recreate Agent jobs scripted out already on the source;

> Note: if the job_owner is not present on the target yet, job creation will fail;

06. On the target recreate Alerts scripted out already on the source

07. On the target recreate Triggers scripted out already on the source

08. On the target configure DBMail and recreate DBMail Profiles scripted out already on the source;

> Note: You need to change the password manually, ask app team for the old ones or set new ones

09. On the target recreate LinkedServers, remember to update the passwords

10. On the target recreate database permissions inside msdb and master

11. Verify if the steps above have been successful

12. Ask another team member (preferably) or check yourself if the following configs seem to be right

```sql
SET NOCOUNT ON;
DECLARE @sql_data_root varchar(256), @back_path sql_variant

EXEC [master].dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',N'SOFTWARE\Microsoft\MSSQLServer\Setup',N'SQLDataRoot',@sql_data_root output

IF SERVERPROPERTY('ProductMajorVersion') >= 1
	BEGIN
		SELECT @back_path = SERVERPROPERTY('InstanceDefaultBackupPath')
	END
ELSE
	BEGIN
		EXEC [master].dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',N'SOFTWARE\Microsoft\MSSQLServer\MSSQLServer', N'BackupDirectory',@back_path output
	END

SELECT
	@@SERVERNAME AS server_name
	,SERVERPROPERTY('ProductVersion') AS [version]
	,(SELECT service_account FROM sys.dm_server_services WHERE LOWER(servicename) LIKE '%sql server%' AND LOWER(servicename) NOT LIKE '%agent%') AS sql_svc_acc
	,(SELECT service_account FROM sys.dm_server_services WHERE LOWER(servicename) LIKE '%agent%') AS agent_svc_acc
	,SERVERPROPERTY('Edition') AS [edition]
	,CASE
		WHEN SERVERPROPERTY('IsIntegratedSecurityOnly') = 0 THEN 'Mixed Mode Authentication'
		ELSE 'Windows Mode Authentication'
	END AS [authentication]
	,SERVERPROPERTY('Collation') AS collation
	,@sql_data_root AS data_root_dir
	,SERVERPROPERTY('InstanceDefaultDataPath') AS def_data_path
	,SERVERPROPERTY('InstanceDefaultLogPath') AS def_log_path
	,@back_path AS def_backup_path;
```

## **Scenario C** (side-by-side migration)

01. Verify that the new instance is up. Cross check configuration between source and target, pay attention to following values: CTP, Max DOP, min and max server memory, AdHoc Distributed Queries, User connections, Remote access, Remote Login timeout, CLR, Backup Compression; Enable traceflags as they were configured on the source (verify if all of them are applicable for new version of SQL, e.g. 1117,1118,2371)

02. On the target recreate logins scripted out already on the source, optionally alter [sa] with hashed password from the old instance

03. On the target recreate Agent operators scripted out already on the source

04. On the target recreate Agent jobs scripted out already on the source;

> Note: if the job_owner is not present on the target yet, it will fail;

> Note: keep them disabled until final steps of the migration

05. On the target recreate Alerts scripted out already on the source

06. On the target recreate Triggers scripted out already on the source

07. On the target configure DBMail and recreate DBMail Profiles scripted out already on the source;

> Note:You need to change the password manually, ask app team for the old ones or set new ones

08. On the target recreate LinkedServers, remember to update the passwords

09. On the target recreate database permissions inside msdb and master

10. Verify if the steps above have been successful

11. Ask another team member (preferably) or check yourself if the following configs seem to be right

```sql
SET NOCOUNT ON;
DECLARE @sql_data_root varchar(256), @back_path sql_variant

EXEC [master].dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',N'SOFTWARE\Microsoft\MSSQLServer\Setup',N'SQLDataRoot',@sql_data_root output

IF SERVERPROPERTY('ProductMajorVersion') >= 1
	BEGIN
		SELECT @back_path = SERVERPROPERTY('InstanceDefaultBackupPath')
	END
ELSE
	BEGIN
		EXEC [master].dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',N'SOFTWARE\Microsoft\MSSQLServer\MSSQLServer', N'BackupDirectory',@back_path output
	END

SELECT
	@@SERVERNAME AS server_name
	,SERVERPROPERTY('ProductVersion') AS [version]
	,(SELECT service_account FROM sys.dm_server_services WHERE LOWER(servicename) LIKE '%sql server%' AND LOWER(servicename) NOT LIKE '%agent%') AS sql_svc_acc
	,(SELECT service_account FROM sys.dm_server_services WHERE LOWER(servicename) LIKE '%agent%') AS agent_svc_acc
	,SERVERPROPERTY('Edition') AS [edition]
	,CASE
		WHEN SERVERPROPERTY('IsIntegratedSecurityOnly') = 0 THEN 'Mixed Mode Authentication'
		ELSE 'Windows Mode Authentication'
	END AS [authentication]
	,SERVERPROPERTY('Collation') AS collation
	,@sql_data_root AS data_root_dir
	,SERVERPROPERTY('InstanceDefaultDataPath') AS def_data_path
	,SERVERPROPERTY('InstanceDefaultLogPath') AS def_log_path
	,@back_path AS def_backup_path;
```

## **Scenario D** (target is the source after fresh install of OS)

01. Verify if you have completed all pre-implementations steps on the source

02. Prepare a restore script for FULL backups

> Note: if you use native SQL backups you can use this script on the source to generate restore script (CHANGE FILEPATHS FOR PHYSICAL FILES)

```sql
--Perform on AUVSQLWNGP04\WIND_DB, copy the result, remove last line ("Completion time..."), execute against LCVSQLWNGP04\WIND_DB,1433, wait for execution (approx. 3 hours)
--SCRIPT FOR FULL RESTORE DURING PRE-RESTORE PHASE
USE tempdb;
SET NOCOUNT ON;
IF OBJECT_ID('#dba_restore_cmd','U') IS NOT NULL BEGIN DROP TABLE #dba_restore_cmd END;
CREATE TABLE #dba_restore_cmd (
	command nvarchar(1000)
	,row_no int identity(1,1)
)
;WITH full_bck_restore_cte AS (
	SELECT
		bs.[database_name] AS [database_name]
		,CAST(bmf.physical_device_name AS varchar(200)) AS physical_device_name
		,ROW_NUMBER() OVER (PARTITION BY bs.[database_name] ORDER BY bs.backup_finish_date DESC) AS row_no
	FROM msdb.dbo.backupset AS bs
	INNER JOIN msdb.dbo.backupmediafamily AS bmf ON bs.media_set_id = bmf.media_set_id
	WHERE 1=1 AND bs.backup_finish_date > DATEADD(DAY, -14, GETDATE()) AND bs.[database_name] NOT IN ('master','msdb','model','tempdb') 
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
	WHEN mr.row_no = 1 THEN CONCAT(CHAR(10),N'RESTORE DATABASE ',QUOTENAME(fbr.[database_name]),' '
			,CHAR(10),'FROM DISK = ',QUOTENAME([physical_device_name],''''),' '
			,CHAR(10),'WITH REPLACE, NORECOVERY'
			,CHAR(10),', ',[move_cmd])
		ELSE CONCAT(', ',[move_cmd])
	END AS [command]
FROM full_bck_restore_cte AS fbr
LEFT JOIN move_restore_cte AS mr ON fbr.[database_name] = mr.[database_name]
WHERE fbr.row_no = 1

DECLARE @restore_cmd nvarchar(1000)
DECLARE cmd_crsr CURSOR LOCAL FAST_FORWARD FOR
SELECT command FROM #dba_restore_cmd ORDER BY row_no ASC
OPEN cmd_crsr;
FETCH NEXT FROM cmd_crsr INTO @restore_cmd
WHILE @@FETCH_STATUS = 0
BEGIN
	PRINT (@restore_cmd)
FETCH NEXT FROM cmd_crsr INTO @restore_cmd
END;
CLOSE cmd_crsr;
DEALLOCATE cmd_crsr;
DROP TABLE #dba_restore_cmd;
```
3. Prepare a restore script for DIFF backups

> Note: if you use native SQL backups you can use this script on the source to generate pre-restore script

```sql
--Perform on AUVSQLWNGP04\WIND_DB, copy the result, remove last line ("Completion time..."), execute against LCVSQLWNGP04\WIND_DB,1433, wait for execution (approx. 1 hour)
--SCRIPT FOR DIFF RESTORE DURING RESTORE PHASE
USE tempdb;
SET NOCOUNT ON;
IF OBJECT_ID('#dba_restore_cmd','U') IS NOT NULL BEGIN DROP TABLE #dba_restore_cmd END;
CREATE TABLE #dba_restore_cmd (
	command nvarchar(1000)
	,row_no int identity(1,1)
)
;WITH full_bck_restore_cte AS (
	SELECT
		bs.[database_name] AS [database_name]
		,CAST(bmf.physical_device_name AS varchar(200)) AS physical_device_name
		,ROW_NUMBER() OVER (PARTITION BY bs.[database_name] ORDER BY bs.backup_finish_date DESC) AS row_no
	FROM msdb.dbo.backupset AS bs
	INNER JOIN msdb.dbo.backupmediafamily AS bmf ON bs.media_set_id = bmf.media_set_id
	WHERE 1=1 AND bs.backup_finish_date > DATEADD(DAY, -14, GETDATE()) AND bs.[database_name] NOT IN ('master','msdb','model','tempdb')
	AND bs.[type] = 'I'
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
				,CHAR(10),'WITH RECOVERY')
		ELSE ''
	END AS [command]
FROM full_bck_restore_cte AS fbr
LEFT JOIN move_restore_cte AS mr ON fbr.[database_name] = mr.[database_name]
WHERE fbr.row_no = 1

DECLARE @restore_cmd nvarchar(1000)
DECLARE cmd_crsr CURSOR LOCAL FAST_FORWARD FOR
SELECT command FROM #dba_restore_cmd ORDER BY row_no ASC
OPEN cmd_crsr;
FETCH NEXT FROM cmd_crsr INTO @restore_cmd
WHILE @@FETCH_STATUS = 0
BEGIN
	PRINT (@restore_cmd)
FETCH NEXT FROM cmd_crsr INTO @restore_cmd
END;
CLOSE cmd_crsr;
DEALLOCATE cmd_crsr;
DROP TABLE #dba_restore_cmd;
```

# Implementation steps

## All scenarios:

01. Create a snapshot of VMs / incremental backup of FileSystem in case of physical servers

## **Scenario A** (source is a new instance with new name and IP)

01. Disable log shipping for databases if applicable

02. Zip system DBs on both the source and target

03. Once the application is stopped, set all user databases to Read-Only on the source; you can create a script for that by running following query

```sql
SELECT
	'ALTER DATABASE ' + name + ' SET SINGLE_USER WITH ROLLBACK IMMEDIATE
	go
	ALTER DATABASE ' + name + ' SET READ_ONLY WITH ROLLBACK IMMEDIATE
	go
	ALTER DATABASE ' + name + ' SET MULTI_USER
	go'
FROM sys.databases
WHERE database_id > 4 AND name <> 'distribution'
```

04. On the source take a diff backup of all databases

05. Restore the diff backup on the target server with RECOVERY

```sql
--Perform on AUVSQLWNGP04\WIND_DB, copy the result, remove last line ("Completion time..."), execute against LCVSQLWNGP04\WIND_DB,1433, wait for execution (approx. 1 hour)
--SCRIPT FOR DIFF RESTORE DURING RESTORE PHASE
USE tempdb;
SET NOCOUNT ON;
IF OBJECT_ID('#dba_restore_cmd','U') IS NOT NULL BEGIN DROP TABLE #dba_restore_cmd END;
CREATE TABLE #dba_restore_cmd (
	command nvarchar(1000)
	,row_no int identity(1,1)
)
;WITH full_bck_restore_cte AS (
	SELECT
		bs.[database_name] AS [database_name]
		,CAST(bmf.physical_device_name AS varchar(200)) AS physical_device_name
		,ROW_NUMBER() OVER (PARTITION BY bs.[database_name] ORDER BY bs.backup_finish_date DESC) AS row_no
	FROM msdb.dbo.backupset AS bs
	INNER JOIN msdb.dbo.backupmediafamily AS bmf ON bs.media_set_id = bmf.media_set_id
	WHERE 1=1 AND bs.backup_finish_date > DATEADD(DAY, -14, GETDATE()) AND bs.[database_name] NOT IN ('master','msdb','model','tempdb')
	AND bs.[type] = 'I'
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
				,CHAR(10),'WITH RECOVERY')
		ELSE ''
	END AS [command]
FROM full_bck_restore_cte AS fbr
LEFT JOIN move_restore_cte AS mr ON fbr.[database_name] = mr.[database_name]
WHERE fbr.row_no = 1

DECLARE @restore_cmd nvarchar(1000)
DECLARE cmd_crsr CURSOR LOCAL FAST_FORWARD FOR
SELECT command FROM #dba_restore_cmd ORDER BY row_no ASC
OPEN cmd_crsr;
FETCH NEXT FROM cmd_crsr INTO @restore_cmd
WHILE @@FETCH_STATUS = 0
BEGIN
	PRINT (@restore_cmd)
FETCH NEXT FROM cmd_crsr INTO @restore_cmd
END;
CLOSE cmd_crsr;
DEALLOCATE cmd_crsr;
DROP TABLE #dba_restore_cmd;
```

06. In case of TDE encrypted database, move it from the source to the target now

* On the source: backup certificate/key, detach the database, copy the files and certificate to the target;
* On the target: create a certificate/key, attach the database)

07. Make sure that the databases are set back to READ_WRITE; you can create a script for that by running following query

```sql
SELECT
	'ALTER DATABASE ' + name + ' SET READ_WRITE
	go'
FROM sys.databases
WHERE database_id > 4 AND name <> 'distribution'
```

08. Enable any jobs that you disabled in step 05 of pre-implementation steps on the target

09. Check configuration of databases on the target - enable snapshot isolation level, broker on these that had this setting enabled on the source

> see step 02 of pre-implementation steps on the source

10. (Optional) Rebuild indexes, update statistics, recompile all objects/run dbcc freeproccache

11. (SSISDB via backup & restore) After restore of SSISDB (step 05), perform following actions:

* Verify if CLR is enabled on the target, if it disable, enable by running the commented out script

```sql
SELECT name,value,value_in_use
FROM sys.configurations
WHERE name = 'clr enabled'
/*
--query to enable CLR
USE master
sp_configure 'clr enabled', 1
RECONFIGURE
*/
```

* Verify if asymetric key MS_SQLEnableSystemAssemblyLoadingKey exists in master, if not, create it with a correct path to to the dll

```sql
USE [master]
SELECT *
FROM sys.asymmetric_keys
WHERE name = 'MS_SQLEnableSystemAssemblyLoadingKey'
/*
--query to create key - NEEDS TO HAVE FILEPATH updated!
CREATE ASYMMETRIC KEY MS_SQLEnableSystemAssemblyLoadingKey
FROM Executable File =
 'C:\Program Files\Microsoft SQL
Server\%VERSION_HERE%\DTS\Binn\Microsoft.SqlServer.IntegrationServices.Server.dll'
*/
```

* Verify if login ##MS_SQLEnableSystemAssemblyLoadingUser## exists, if not, create it

```sql
SELECT *
FROM sys.server_principals
WHERE name = '##MS_SQLEnableSystemAssemblyLoadingUser##'
/*
--query to create login and grant permissions to it
CREATE LOGIN ##MS_SQLEnableSystemAssemblyLoadingUser##
FROM ASYMMETRIC KEY MS_SQLEnableSystemAssemblyLoadingKey
GRANT UNSAFE ASSEMBLY TO ##MS_SQLEnableSystemAssemblyLoadingUser##
*/
```

* Create login ##MS_SSISServerCleanupJobLogin##

* Create procedure master.dbo.sp_ssis_startup

* Create Agent job [SSIS Server Maintenance Job]

* Map SSISDB user ##MS_SSISServerCleanupJobUser## to ##MS_SSISServerCleanupJobLogin##

```sql
USE SSISDB
EXEC sp_change_users_login 'update_one', '##MS_SSISServerCleanupJobUser##','##MS_SSISServerCleanupJobLogin##'
```

* Restore backup of SSISDB Master Key OR if you know Master Key, open it with password and re-encrypt it with new Service Master Key

```sql
USE SSISDB
RESTORE MASTER KEY FROM FILE = '%filepath%\%databasename%'
	DECRYPTION BY PASSWORD = 'xxx'
	ENCRYPTION BY PASSWORD = 'yyy'
FORCE

--OR

-- USE SSISDB
-- OPEN MASTER KEY DECRYPTION BY PASSWORD = 'xxx'
-- ALTER MASTER KEY ADD ENCRYPTION BY SERVICE MASTER KEY
```

* In SSMS go to the Object Explorer, expand Integration Service Catalog, right click on it and choose Update Database... option.Alternatively you can go to C:\Program Files\Microsoft SQL Server\<u>150</u>\DTS\Binn\ (change version number in the underlined part) and run ISDBUpgradeWizard.exe manually

12. (SSRS via backup & restore) After restore of ReportServer and ReportServerTempDB (step 05), perform following actions:

* Recreate RSExecRole on master <u>and</u> msdb on new instance

* Reconfigure SSRS as per requirements and in Encryption Keys tab restore the backup

* Run following query in the ReportServer database, if there are more than 2 keys (current instance and NULL), delete the key for the old instance

```sql
USE ReportServer
SELECT * FROM dbo.Keys
```

* If the old RSReportServer.config and RSWebApplication.config files had a custom modifications make necessary changes in the files used by new SSRS

* Restart SSRS

13. (SSAS via backup & restore) Take full backups of SSAS databases: Connect to SSAS instance via SSMS, right click on a database, choose "Backup up", provide a name of backup .abf file)

14. (SSAS via backup & restore) Restore the database: Connect to SSAS instance via SSMS, right click on Databases, choose "Restore", provide Backup file name, Restore database (name of the restored database), Storage location (where files of SSAS database will be stored), choose Overwrite security information to copy permissions from the source instance

15. (SSAS via backup & restore) If the application team won't perform post implementation tasks for SSAS databases (Updates compatibility level, Process, Run DBCC), perform the steps as described in section below about SSAS **[Scenario A (backup & restore)]**

16. Ask app team to restart the application with changed connections strings

17. Monitor the situation once the applications are up

18. (Optional) On the source take databases offline

## **Scenario B** (source is a new instance with new name and IP, migration done via HA solutions)

01. Disable log shipping for databases if applicable

02. Zip system DBs on both the source and target

03. Once the application is stopped perform a failover so the new instance becomes active/primary

04. (Optional) Rebuild indexes, update statistics, recompile all objects/run dbcc freeproccache

05. (SSISDB via backup & restore) After restore of SSISDB (step 05), perform following actions:

* In SSMS go to the Object Explorer, expand Integration Service Catalog, right click on it and choose Update Database... option
Alternatively you can go to C:\Program Files\Microsoft SQL Server\<u>150</u>\DTS\Binn\ (change version name in underlined part) and run ISDBUpgradeWizard.exe manually

06. (SSAS via backup & restore) Take full backups of SSAS databases: Connect to SSAS instance via SSMS, right click on a database, choose "Backup up", provide a name of backup .abf file)

07. (SSAS via backup & restore) Restore the database: Connect to SSAS instance via SSMS, right click on Databases, choose "Restore", provide Backup file name, Restore database (name of the restored database), Storage location (where files of SSAS database will be stored), choose Overwrite security information to copy permissions from the source instance

08. (SSAS via backup & restore) If the application team won't perform post implementation tasks for SSAS databases (Updates compatibility level, Process, Run DBCC), perform the steps as described in section below about SSAS **[Scenario A (backup & restore)]**

09. Ask app team to restart the application with changed connections strings

10. Monitor the situation once the applications are up

11. (Optional) On the source take databases offline

## **Scenario C** (side-by-side migration)

01. Disable log shipping for databases if applicable

02. Zip system DBs on both the source and target

03. (Optional) Once the application is stopped, set all user databases to Read-Only on the source; you can create a script for that by running following query

```sql
SELECT
	'ALTER DATABASE ' + name + ' SET SINGLE_USER WITH ROLLBACK IMMEDIATE
	go
	ALTER DATABASE ' + name + ' SET READ_ONLY WITH ROLLBACK IMMEDIATE
	go
	ALTER DATABASE ' + name + ' SET MULTI_USER
	go'
FROM sys.databases
WHERE database_id > 4 AND name <> 'distribution'
```

04. On the source take a diff backup of all databases

05. Detach all databases on the source

06. Attach all databases on the target

07. (SSISDB via backup & restore) After attaching SSISDB (step 05), perform following actions:

* Verify if CLR is enabled on the target, if it's disable, enable by running the commented out script

```sql
SELECT name,value,value_in_use
FROM sys.configurations
WHERE name = 'clr enabled'
/*
--query to enable CLR
USE master
sp_configure 'clr enabled', 1
RECONFIGURE
*/
```

* Verify if asymetric key MS_SQLEnableSystemAssemblyLoadingKey exists in master, if not, create it with a correct path to to the dll

```sql
USE [master]
SELECT *
FROM sys.asymmetric_keys
WHERE name = 'MS_SQLEnableSystemAssemblyLoadingKey'
/*
--query to create key - NEEDS TO HAVE FILEPATH updated!
CREATE ASYMMETRIC KEY MS_SQLEnableSystemAssemblyLoadingKey
FROM Executable File =
 'C:\Program Files\Microsoft SQL
Server\%VERSION_HERE%\DTS\Binn\Microsoft.SqlServer.IntegrationServices.Server.dll'
*/
```

* Verify if login ##MS_SQLEnableSystemAssemblyLoadingUser## exists, if not, create it

```sql
SELECT *
FROM sys.server_principals
WHERE name = '##MS_SQLEnableSystemAssemblyLoadingUser##'
/*
--query to create login and grant permissions to it
CREATE LOGIN ##MS_SQLEnableSystemAssemblyLoadingUser##
FROM ASYMMETRIC KEY MS_SQLEnableSystemAssemblyLoadingKey
GRANT UNSAFE ASSEMBLY TO ##MS_SQLEnableSystemAssemblyLoadingUser##
*/
```

* Create login ##MS_SSISServerCleanupJobLogin##

* Create procedure master.dbo.sp_ssis_startup

* Create Agent job [SSIS Server Maintenance Job]

* Map SSISDB user ##MS_SSISServerCleanupJobUser## to ##MS_SSISServerCleanupJobLogin##

```sql
USE SSISDB
EXEC sp_change_users_login 'update_one', '##MS_SSISServerCleanupJobUser##','##MS_SSISServerCleanupJobLogin##'
```

* Restore backup of SSISDB Master Key OR if you know Master Key, open it with password and re-encrypt it with new Service Master Key

```sql
USE SSISDB
RESTORE MASTER KEY FROM FILE = '%filepath%\%databasename%'
	DECRYPTION BY PASSWORD = 'xxx'
	ENCRYPTION BY PASSWORD = 'yyy'
FORCE

--OR

-- USE SSISDB
-- OPEN MASTER KEY DECRYPTION BY PASSWORD = 'xxx'
-- ALTER MASTER KEY ADD ENCRYPTION BY SERVICE MASTER KEY
```

* In SSMS go to the Object Explorer, expand Integration Service Catalog, right click on it and choose Update Database... option\ Alternatively you can go to C:\Program Files\Microsoft SQL Server\<u>150</u>\DTS\Binn\ (change version name in underlined part) and run ISDBUpgradeWizard.exe manually

08. (SSRS via backup & restore) After attaching ReportServer and ReportServerTempDB (step 05), perform following actions:

* Recreate RSExecRole on master <u>and</u> msdb on new instance

* Reconfigure SSRS as per requirements and in Encryption Keys tab restore the backup

* Run following query in the ReportServer database, if there are more than 2 keys (current instance and NULL), delete the key for the old instance

```sql
USE ReportServer
SELECT * FROM dbo.Keys
```

* If the old RSReportServer.config and RSWebApplication.config files had a custom modifications make necessary changes in the files used by new SSRS

* Restart SSRS

09. (SSAS via backup & restore) Take full backups of SSAS databases: Connect to SSAS instance via SSMS, right click on a database, choose "Backup up", provide a name of backup .abf file)

10. (SSAS via backup & restore) Restore the database: Connect to SSAS instance via SSMS, right click on Databases, choose "Restore", provide Backup file name, Restore database (name of the restored database), Storage location (where files of SSAS database will be stored), choose Overwrite security information to copy permissions from the source instance

11. (SSAS via backup & restore) If the application team won't perform post implementation tasks for SSAS databases (Updates compatibility level, Process, Run DBCC), perform the steps as described in section below about SSAS **[Scenario A (backup & restore)]**

12. In case of TDE encrypted database, move it from the source to the target now

* On the source: backup certificate/key, detach the database, copy the files and certificate to the target;

* On the target: create a certificate/key, attach the database)

13. Make sure that the databases are set back to READ_WRITE; you can create a script for that by running following query

```sql
SELECT
	'ALTER DATABASE ' + name + ' SET READ_WRITE
	go'
FROM sys.databases
WHERE database_id > 4 AND name <> 'distribution'
```

14. Enable any jobs that you disabled in step 05 of pre-implementation steps on the target

15. Check configuration of databases on the target - enable snapshot isolation level, broker on these that had this setting enabled on the source

> see step 02 of pre-implementation steps on the source

16. (Optional) Rebuild indexes, update statistics, recompile all objects/run dbcc freeproccache

17. Ask app team to restart the application with changed connections strings

18. Monitor the situation once the applications are up

## **Scenario D** (target is the source after fresh install of OS)

01. Disable log shipping for databases if applicable

02. On the source take diff backup and verify if it was successful

> Note: this is not applicable for TDE encrypted databases;

03. Wait for the OS to be reinstalled

04. Perform a fresh installation of SQL on the host and configure it to match the configuration of the source

05. On the target restore the databases from full backup

06. On the target recreate logins scripted out already on the source

07. On the target recreate Agent operators scripted out already on the source

08. On the target recreate Agent jobs scripted out already on the source;

> Note: if the job_owner is not present on the target yet, job creation will fail;

09. (SSISDB via backup & restore) After restore of SSISDB (step 05), perform following actions:

* Verify if CLR is enabled on the target, if it's disable, enable by running the commented out script

```sql
SELECT name,value,value_in_use
FROM sys.configurations
WHERE name = 'clr enabled'
/*
--query to enable CLR
USE master
sp_configure 'clr enabled', 1
RECONFIGURE
*/
```

* Verify if asymetric key MS_SQLEnableSystemAssemblyLoadingKey exists in master, if not, create it with a correct path to to the dll

```sql
USE [master]
SELECT *
FROM sys.asymmetric_keys
WHERE name = 'MS_SQLEnableSystemAssemblyLoadingKey'
/*
--query to create key - NEEDS TO HAVE FILEPATH updated!
CREATE ASYMMETRIC KEY MS_SQLEnableSystemAssemblyLoadingKey
FROM Executable File =
 'C:\Program Files\Microsoft SQL
Server\%VERSION_HERE%\DTS\Binn\Microsoft.SqlServer.IntegrationServices.Server.dll'
*/
```

* Verify if login ##MS_SQLEnableSystemAssemblyLoadingUser## exists, if not, create it

```sql
SELECT *
FROM sys.server_principals
WHERE name = '##MS_SQLEnableSystemAssemblyLoadingUser##'
/*
--query to create login and grant permissions to it
CREATE LOGIN ##MS_SQLEnableSystemAssemblyLoadingUser##
FROM ASYMMETRIC KEY MS_SQLEnableSystemAssemblyLoadingKey
GRANT UNSAFE ASSEMBLY TO ##MS_SQLEnableSystemAssemblyLoadingUser##
*/
```

* Create login ##MS_SSISServerCleanupJobLogin##

* Create procedure master.dbo.sp_ssis_startup

* Create Agent job [SSIS Server Maintenance Job]

* Map SSISDB user ##MS_SSISServerCleanupJobUser## to ##MS_SSISServerCleanupJobLogin##

```sql
USE SSISDB
EXEC sp_change_users_login 'update_one', '##MS_SSISServerCleanupJobUser##','##MS_SSISServerCleanupJobLogin##'
```

* Restore backup of SSISDB Master Key OR if you know Master Key, open it with password and re-encrypt it with new Service Master Key

```sql
USE SSISDB
RESTORE MASTER KEY FROM FILE = '%filepath%\%databasename%'
	DECRYPTION BY PASSWORD = 'xxx'
	ENCRYPTION BY PASSWORD = 'yyy'
FORCE

--OR

-- USE SSISDB
-- OPEN MASTER KEY DECRYPTION BY PASSWORD = 'xxx'
-- ALTER MASTER KEY ADD ENCRYPTION BY SERVICE MASTER KEY
```

* In SSMS go to the Object Explorer, expand Integration Service Catalog, right click on it and choose Update Database... option
Alternatively you can go to C:\Program Files\Microsoft SQL Server\<u>150</u>\DTS\Binn\ (change version name in underlined part) and run ISDBUpgradeWizard.exe manually

10. (SSRS via backup & restore) After restore of ReportServer and ReportServerTempDB (step 05), perform following actions:

* Recreate RSExecRole on master and msdb on new instance

* Reconfigure SSRS as per requirements and in Encryption Keys tab restore the backup

* Run following query in the ReportServer database, if there are more than 2 keys (current instance and NULL), delete the key for the old instance

```sql
USE ReportServer
SELECT * FROM dbo.Keys
```

* If the old RSReportServer.config and RSWebApplication.config files had a custom modifications make necessary changes in the files used by new SSRS


* Restart SSRS

11. (SSAS via backup & restore) Take full backups of SSAS databases: Connect to SSAS instance via SSMS, right click on a database, choose "Backup up", provide a name of backup .abf file)

12. (SSAS via backup & restore) Restore the database: Connect to SSAS instance via SSMS, right click on Databases, choose "Restore", provide Backup file name, Restore database (name of the restored database), Storage location (where files of SSAS database will be stored), choose Overwrite security information to copy permissions from the source instance

13. (SSAS via backup & restore) If the application team won't perform post implementation tasks for SSAS databases (Updates compatibility level, Process, Run DBCC), perform the steps as described in section below about SSAS **[Scenario A (backup & restore)]**

14. On the target recreate Alerts scripted out already on the source

15. On the target configure DBMail and recreate DBMail Profiles scripted out already on the source;

> Note: you need to change the password manually, ask app team for the old ones or set new ones

16. On the target recreate LinkedServers

17. On the target recreate database permissions inside msdb

18. Verify if the steps above have been successful

# **Post-Implementation steps**

## **Scenario A** (source is a new instance with new name and IP)

01. Verify if you haven't left your own login as the owner of the restored databases

```sql
--Databases with owners different than default SA
SELECT name, suser_sname(owner_sid) AS OwnerName
FROM sys.databases
WHERE owner_sid <> 0x01

--Create command to alter authorization
SELECT 'ALTER AUTHORIZATION ON database::'+name+' TO '+ suser_sname(0x01)+'; '
FROM sys.databases
WHERE owner_sid <> 0x01
```

02. Enable log shipping for databases if applicable

> Note: Remember that the script should be run on all members of log shipping configuration

03. (Optional) Create a CNAME entry / DNS alias pointing from the old server to the new one - ask DNS/Network team to do that

04. (Optional) In case of FCI clusters

* On the source: alter Virtual Names, e.g. add x in the beginning of the name

* On the target: alter Virtual Names to match the names on the source before step above

05. Create SPNs if necessary

```cmd
setspn -s mssqlsvc/%fqdn%:%port% %account%
setspn -s mssqlsvc/%fqdn%:%instancename% %account%
setspn -s mssqlsvc/%servername%:%port% %account%
setspn -s mssqlsvc/%servername%:%instancename% %account%
setspn -s mssqlsvc/%aoag_listener_fqdn%:%port% %account%
setspn -s mssqlsvc/%aoag_listener_fqdn%:%instancename% %account%
setspn -s mssqlsvc/%aoag_listener_name%:%port% %account%
setspn -s mssqlsvc/%aoag_listener_name%:%instancename% %account%
```

06. (After some period) Consider changing compatibility level to a higher one, if needed by the application

## **Scenario B** (source is a new instance with new name and IP, migration done via HA solutions)

01. Verify if you haven't left your own login as the owner of the restored databases

```sql
--Databases with owners different than default SA
SELECT name, suser_sname(owner_sid) AS OwnerName
FROM sys.databases
WHERE owner_sid <> 0x01

--Create command to alter authorization
SELECT 'ALTER AUTHORIZATION ON database::'+name+' TO '+ suser_sname(0x01)+'; '
FROM sys.databases
WHERE owner_sid <> 0x01
```

02. Enable log shipping for databases if applicable

> Note: Remember that the script should be run on all members of log shipping configuration

03. (Optional) Create a CNAME entry / DNS alias pointing from the old server to the new one - ask DNS/Network team to do that

04. (Optional) In case of FCI clusters

* On the source: alter Virtual Names, e.g. add x in the beginning of the name

* On the target: alter Virtual Names to match the names on the source before step above

05. Create SPNs if necessary

```cmd
setspn -s mssqlsvc/%fqdn%:%port% %account%
setspn -s mssqlsvc/%fqdn%:%instancename% %account%
setspn -s mssqlsvc/%servername%:%port% %account%
setspn -s mssqlsvc/%servername%:%instancename% %account%
setspn -s mssqlsvc/%aoag_listener_fqdn%:%port% %account%
setspn -s mssqlsvc/%aoag_listener_fqdn%:%instancename% %account%
setspn -s mssqlsvc/%aoag_listener_name%:%port% %account%
setspn -s mssqlsvc/%aoag_listener_name%:%instancename% %account%
```

06. (After some period) Consider changing compatibility level to a higher one, if needed by the application

## **Scenario C** (side-by-side migration)

01. Verify if you haven't left your own login as the owner of the restored databases

```sql
--Databases with owners different than default SA
SELECT name, suser_sname(owner_sid) AS OwnerName
FROM sys.databases
WHERE owner_sid <> 0x01

--Create command to alter authorization
SELECT 'ALTER AUTHORIZATION ON database::'+name+' TO '+ suser_sname(0x01)+'; '
FROM sys.databases
WHERE owner_sid <> 0x01
```

02. Enable log shipping for databases if applicable

> Note: Remember that the script should be run on all members of log shipping configuration

03. (Optional) Create a CNAME entry / DNS alias pointing from the old server to the new one - ask DNS/Network team to do that

04. (Optional) In case of FCI clusters

* On the source: alter Virtual Names, e.g. add x in the beginning of the name

* On the target: alter Virtual Names to match the names on the source before step above

05. Create SPNs if necessary

```cmd
setspn -s mssqlsvc/%fqdn%:%port% %account%
setspn -s mssqlsvc/%fqdn%:%instancename% %account%
setspn -s mssqlsvc/%servername%:%port% %account%
setspn -s mssqlsvc/%servername%:%instancename% %account%
setspn -s mssqlsvc/%aoag_listener_fqdn%:%port% %account%
setspn -s mssqlsvc/%aoag_listener_fqdn%:%instancename% %account%
setspn -s mssqlsvc/%aoag_listener_name%:%port% %account%
setspn -s mssqlsvc/%aoag_listener_name%:%instancename% %account%
```

06. (After some period) Consider changing compatibility level to a higher one, if needed by the application


## **Scenario D** (target is the source after fresh install of OS)

01. Verify if you haven't left your own login as the owner of the restored databases

```sql
--Databases with owners different than default SA
SELECT name, suser_sname(owner_sid) AS OwnerName
FROM sys.databases
WHERE owner_sid <> 0x01

--Create command to alter authorization
SELECT 'ALTER AUTHORIZATION ON database::'+name+' TO '+ suser_sname(0x01)+'; '
FROM sys.databases
WHERE owner_sid <> 0x01
```

02. Enable log shipping for databases if applicable

> Note: Remember that the script should be run on all members of log shipping configuration

03. (Optional) Create a CNAME entry / DNS alias pointing from the old server to the new one - ask DNS/Network team to do that

04. (Optional) In case of FCI clusters

* On the source: alter Virtual Names, e.g. add x in the beginning of the name

* On the target: alter Virtual Names to match the names on the source before step above

05. Create SPNs if necessary

```cmd
setspn -s mssqlsvc/%fqdn%:%port% %account%
setspn -s mssqlsvc/%fqdn%:%instancename% %account%
setspn -s mssqlsvc/%servername%:%port% %account%
setspn -s mssqlsvc/%servername%:%instancename% %account%
setspn -s mssqlsvc/%aoag_listener_fqdn%:%port% %account%
setspn -s mssqlsvc/%aoag_listener_fqdn%:%instancename% %account%
setspn -s mssqlsvc/%aoag_listener_name%:%port% %account%
setspn -s mssqlsvc/%aoag_listener_name%:%instancename% %account%
```

06. (After some period) Consider changing compatibility level to a higher one, if needed by the application

07. Cleanup old installation of SQL server


# **Rollback steps**

## **Scenario A** (source is a new instance with new name and IP)

01.  Go back to the old instance

02.  Change databases back to read-write

03.  Ask app team to use pre-migration connection strings

04.  Enable log shipping for databases if applicable

> Note: Remember that the script should be run on all members of log shipping configuration

## **Scenario B** (source is a new instance with new name and IP, migration done via HA solutions)

01.  Drop databases in HA solution (you cannot failback from newer version to an older one)

02.  Restore databases on the old instance

03.  Ask app team to use pre-migration connection strings

04.  Enable log shipping for databases if applicable

> Note: Remember that the script should be run on all members of log shipping configuration

## **Scenario C** (side-by-side migration)

01.  Go back to the old instance

02.  Detach all databases from the target and attach them back

> Note: in case any of the database has been update to a compatibility level above the version of the source, it won't be possible to attach it back to the source - you need to perform a restore

03.  Ask app team to use pre-migration connection strings

04.  Enable log shipping for databases if applicable

> Note: Remember that the script should be run on all members of log shipping configuration

## **Scenario D** (target is the source after fresh install of OS)

01.  "Bare metal restore"

02.  If OS and/or FS needs to be restored, wait for Windows team to do that

03.  Perform a fresh installation of SQL in the old version, restore databases from backups

# **Migration of additional features**

## **SSIS**

### **Scenario A** (backup & restore)

**Pre-Implementation steps**

01.  Check if you have the password used for creation of Integration Service Catalog (Master Key). If you don't have it, you can either simply take a backup of current Master Key (see step above), if you have it, still it's reasonable to take this backup as well

```sql
USE [database]
BACKUP MASTER KEY TO FILE = 'folder\db.key' ENCRYPTION BY PASSWORD = 'xxx' --run at old instance
```

2.  Perform following points:

* Script out login ##MS_SSISServerCleanupJobLogin##

* Script out procedure master.dbo.sp_ssis_startup

* Script out Agent job [SSIS Server Maintenance Job]

* Export each project from Integration Service Catalog (.ispac file)

03. Take a full backup of SSISDB

**Implementation steps**

01.  Verify if CLR is enabled on the target, if it's disable, enable by running the commented out script

```sql
SELECT name,value,value_in_use
FROM sys.configurations
WHERE name = 'clr enabled'
/*
--query to enable CLR
USE master
sp_configure 'clr enabled', 1
RECONFIGURE
*/
```

02.  Verify if asymetric key MS_SQLEnableSystemAssemblyLoadingKey exists in master, if not, create it with a correct path to to the dll

```sql
USE [master]
SELECT *
FROM sys.asymmetric_keys
WHERE name = 'MS_SQLEnableSystemAssemblyLoadingKey'
/*
--query to create key - NEEDS TO HAVE FILEPATH updated!
CREATE ASYMMETRIC KEY MS_SQLEnableSystemAssemblyLoadingKey
FROM Executable File =
 'C:\Program Files\Microsoft SQL
Server\%VERSION_HERE%\DTS\Binn\Microsoft.SqlServer.IntegrationServices.Server.dll'
*/
```

03.  Verify if login ##MS_SQLEnableSystemAssemblyLoadingUser## exists, if not, create it

```sql
SELECT *
FROM sys.server_principals
WHERE name = '##MS_SQLEnableSystemAssemblyLoadingUser##'
/*
--query to create login and grant permissions to it
CREATE LOGIN ##MS_SQLEnableSystemAssemblyLoadingUser##
FROM ASYMMETRIC KEY MS_SQLEnableSystemAssemblyLoadingKey
GRANT UNSAFE ASSEMBLY TO ##MS_SQLEnableSystemAssemblyLoadingUser##
*/
```

04.  Create login ##MS_SSISServerCleanupJobLogin##

05.  Create procedure master.dbo.sp_ssis_startup

06.  Create Agent job [SSIS Server Maintenance Job]

07.  Map SSISDB user ##MS_SSISServerCleanupJobUser## to ##MS_SSISServerCleanupJobLogin##

```sql
USE SSISDB
EXEC sp_change_users_login 'update_one', '##MS_SSISServerCleanupJobUser##','##MS_SSISServerCleanupJobLogin##'
```

08.  Restore backup of SSISDB Master Key OR if you know Master Key, open it with password and re-encrypt it with new Service Master Key

```sql
USE SSISDB
RESTORE MASTER KEY FROM FILE = '%filepath%\%databasename%'
	DECRYPTION BY PASSWORD = 'xxx'
	ENCRYPTION BY PASSWORD = 'yyy'
FORCE

--OR

-- USE SSISDB
-- OPEN MASTER KEY DECRYPTION BY PASSWORD = 'xxx'
-- ALTER MASTER KEY ADD ENCRYPTION BY SERVICE MASTER KEY
```

09.  In SSMS go to the Object Explorer, expand Integration Service Catalog, right click on it and choose Update Database... option\ Alternatively you can go to C:\Program Files\Microsoft SQL Server\<u>150</u>\DTS\Binn\ (change version name in underlined part) and run ISDBUpgradeWizard.exe manually

10. Take a backup of SSISDB Master Key (Step 1 from Pre-Implementation Steps)

### **Scenario B** (Deploy a project from Visual Studio Integration Services Project)

**Pre-Implementation Steps**

01.  Check if you have the password used for creation of Integration Service Catalog (Master Key). If you don't have it, you can either simply take a backup of current Master Key (see step above), if you have it, still it's reasonable to take this backup as well

```sql
USE [database]
BACKUP MASTER KEY TO FILE = 'folder\db.key' ENCRYPTION BY PASSWORD = 'xxx' --run at old instance
```

02.  Script all users from SSISDB on the old instance along with their permissions

03.  Export each project from Integration Service Catalog (.ispac file)

04.  Take full backup of SSISDB

05.  Ask team supporting SSIS to go to Visual Studio, right click on the Project, choose Property and change the target server version to the proper version of SQL Server and click Apply, then yes and OK. Afterwards SSIS team should deliver the .ispac file to you.

**Implementation Steps**

01.  Go to Integration Services Catalog, right click and create a new Catalog, provide new strong password

02.  Expand the catalog and recreate folders the same way as on the old instance

03.  Ask SSIS team to deploy Projects OR right clik on the folder, go to Projects, choose Deploy, point to the .ispac file. If you have environment variables you need to create them manually as they are not part of the project. Since it is a new deployment, it will not carry over the history of job executions or the deployed project versions

04.  Recreate users with their permissions as per state on the old instance (Step 03 from Pre-Implementation Steps)

## **SSRS**

### **Scenario A** (backup & restore)

**Pre-Implementation Steps**

01.  In Reporting Services Configuration Manager on the source instance, check Database tab and verify if the SSRS is using default DBs, i.e. ReportServer and ReportServerTempDB, if not, then use the non-default names in the next steps

02.  In Reporting Services Configuration Manager on the source instance, open Encryption Keys, take a backup protected by strong password

03.  Take a screenshot of all configurations in Reporting Services Configuration Manager, i.e. tabs Servie Account, Web Service URL, Database, Rerport Server Database etc.

04.  Take full backup of ReportServer and ReportServerTempDB

05.  Script out databas role RSExecRole from master <u>and</u> msdb

06.  Make a copy following files RSReportServer.config and RSWebApplication.config

**Implementation Steps**

01.  Recreate RSExecRole on master <u>and</u> msdb on new instance (Step 5 from Pre-Implementation Steps)

02.  Restore ReportServer and ReportServerTempDB

03.  Reconfigure SSRS as per requirements (see Step 3 from Pre-Implementation Steps) and in Encryption Keys tab restore the backup from Step 2 from Pre-Implementation Steps

04.  Run following query in the ReportServer database, if there are more than 2 keys (current instance and NULL), delete the key for the old instance

```sql
USE ReportServer
SELECT * FROM dbo.Keys
```

05.  If the old RSReportServer.config and RSWebApplication.config files had a custom modifications make necessary changes in the files used by new SSRS

06.  Restart SSRS

## **SSAS**

### **Scenario A** (backup & restore)

**Pre-Implementation Steps**

01.  Take full backups of SSAS databases: Connect to SSAS instance via SSMS, right click on a database, choose "Backup up", provide a name of backup .abf file

**Implementation Steps**

01.  Restore the database: Connect to SSAS instance via SSMS, right click on Databases, choose "Restore", provide Backup file name, Restore database (name of the restored database), Storage location (where files of SSAS database will be stored), choose Overwrite security information to copy permissions from the source instance

**Post-Implementation Steps**

01.  Update compatibility level of multidimensional SSAS DB (if source was SSAS2008 or earlier)

* Connect to SSAS instance via SSMS and run following MDX query to     verify compatibility levels:

```dmx
SELECT [Catalog_Name], Compatibility_level FROM $SYSTEM.DBSCHEMA_CATALOGS
```

* Right click database, choose Script Database as > ALTER > New Query Editor Window. In the XMLA representation (the query), add following line after line </Annotations\>

```dmx
<ddl200:CompatibilityLevel\>1100</ddl200:CompatibilityLevel\>
```

* Run the script and verify the results once again

02.  Update compatibility level of tabular SSAS DB

* Action to be performed by application team via Visual Studio

3.  Process the databases ():

* following DMX script for multidimensional databases and     tabular databases with compatibility level \<1200

```dmx
SELECT   '<Process xmlns="http://schemas.microsoft.com/analysisservices/2003/engine">
  <Type>ProcessFull</Type>
  <Object>
    <DatabaseID>' + [CATALOG_NAME] + '</DatabaseID>
  </Object>
</Process>
' FROM $SYSTEM.DBSCHEMA_CATALOGS
```

* Modify the outcome by adding following lines in the beginning and end:

```dmx
<Batch Transaction="0" xmlns="http://schemas.microsoft.com/analysisservices/2003/engine">
…
</Batch>
```

* Run the script

* For tabular databases with compatibility level 1200+, right click the databsae, choose Process Database, click OK
4.  Run Database Consistency Checks

* Create a DBCC script for multidimensional databases and tabular     databases with compatibility level \<1200 by running following     DMX script

```dmx
SELECT   '<DBCC xmlns="http://schemas.microsoft.com/analysisservices/2003/engine">
   <Object>
      <DatabaseID>' + [CATALOG_NAME] + '</DatabaseID>
   </Object>
</DBCC>' FROM $SYSTEM.DBSCHEMA_CATALOGS WHERE COMPATIBILITY_LEVEL < 1200
```

* Save the script and run DBCC commands against each database separately

* Generate a DBCC script for tabular databases with compatibility level 1200+ by running following DMX script

```dmx
SELECT   '<DBCC xmlns="http://schemas.microsoft.com/analysisservices/2014/engine">
      <DatabaseID>' + [CATALOG_NAME] + '</DatabaseID>
</DBCC>' FROM $SYSTEM.DBSCHEMA_CATALOGS WHERE COMPATIBILITY_LEVEL >= 1200
```

* Save the script and run DBCC commands against each database separately

# **Further reading:**

**SQL Server**

https://docs.microsoft.com/en-us/sql/database-engine/install-windows/choose-a-database-engine-upgrade-method?view=sql-server-ver15
https://www.mssqltips.com/sqlservertip/1936/sql-server-database-migration-checklist/
https://www.sqlshack.com/sql-server-database-migration-best-practices-low-risk-downtime/
https://www.brentozar.com/archive/2015/03/why-you-shouldnt-upgrade-sql-server/

**SSIS**

https://docs.microsoft.com/en-us/sql/integration-services/catalog/ssis-catalog?view=sql-server-ver15
https://www.mssqltips.com/sqlservertip/6831/how-to-migrate-ssisdb-to-another-server/https://www.sqlshack.com/moving-the-ssisdb-catalog-on-a-new-sql-server-instance/

**SSRS**

https://www.sqlservercentral.com/articles/migrating-sql-server-reporting-services
https://docs.microsoft.com/en-us/sql/reporting-services/install-windows/migrate-a-reporting-services-installation-native-mode?view=sql-server-ver15
https://docs.microsoft.com/en-us/sql/reporting-services/install-windows/upgrade-and-migrate-reporting-services?view=sql-server-ver15

**SSAS**

https://www.mssqltips.com/sqlservertip/6296/sql-server-analysis-services-migration-from-sql-server-2012-to-sql-server-2017/https://www.mssqltips.com/sqlservertip/1906/how-to-restore-a-sql-server-analysis-services-database/
