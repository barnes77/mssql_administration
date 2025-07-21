**Author:** Mateusz Wierzbowski

**Created:** 2021/02/01

**Revised:** n/a

# Contents
 - [General consideration](#general-consideration)
 - [Prerequisites](#prerequisites)
 - [Preparations](#preparations)
 - [Standalone instance](#standalone-instance)
 - [AlwaysOn cluster](#alwayson-cluster)
 - [FCI instance](#fci-instance)
 - [Other information](#other-information)
 - [Useful commands](#useful-commands)
 - [Downtime estimations](#dontime-estimations)
 - [Further reading](#further-reading)

# General consideration
!!!IMPORTANT!!! After SQL2016 both SSAS and SSRS are standalone products and as such there's no way to perform an inplace upgrade from SSAS/SSRS <2016 to SSAS/SSRS 2017+. You need to consider a migration (even side-by-side) for these two features.
 
# Prerequisites
* Licence key for new SQL version and correct edition
* Password for service account (needed for a failback on a physical server) & verification if the password hasn't expired already
 
# Preparations
* Week before 
    * Verify that there are no missing files in installer cache: either using FileSQLInstalls.vbs or e.g. FixMissingMSI ( https://github.com/suyouquan/SQLSetupTools ) and handle any missing ones
    * Verify if there are any components (SSRS/SSIS/SSAS) installed and how to handle them during the upgrade
* Day before
    * Copy installation of new SQL server to target host
    * Copy patches to target host and place them in the subfolder of RTM installation file, e.g. .\Updates
    * Make a full backup server to be patched - run full backup of SQLServer
    * Schedule maintenance mode for the implementation
    * Backup SMK (Service Master Key)
 
# Standalone instance
**Implementation**
* Verify that full backups were completed successfully
* Make a diff backup of the server to be patched - physical server: FS backup + SQL backup; virtual machine: VM snapshot + SQL backup
* Verify that diff backups were completed successfully
* Take a copy of physical files of systemDBsfor each instance
* Run installer of new SQL Server version, slipstream updates & reboot the host afterwards
* Verify Setup Bootstrap log - summary*.txt and config.ini
* Take a copy of physical files of systemDBsfor each instance
* Rerun steps 05-07 for other SQL instances on the host
* Verify connection to SQL instance
 
**After implementation steps:**
* Verify that all databases came back online (except for the ones that were offline before the upgrade)
* Complete full dbcc checkdb for all databases
* Handle possible issues that may arise after checkdb (repair_rebuild/restore from backup)
* Run full backup of all databases
 
**Fallback plan**:
* Virtual server
    * Restore OS from snapshot - contact Windows team
* Physical server
    * Get the password for the service account of the SQL instance (not done – support from IAM team would be needed)
    * Uninstall SQL Server on the async secondary
    * Install SQL Server with the former version, patch it to match build from before the upgrade
    * Restore the databases from last known good backup
 
# AlwaysOn cluster

<i>example of primary+sync secondary+async secondary</i>

**General tasks**
* Verify if full backup is taken successfully, take diff backups
* Verify the status of AG group - in case of any issues resolve them
* Change automatic failover types to manual in GUI for AlwaysOn Availability Groups, if applicable

**Start the upgrade on the asynchronous replica**
* Take a copy of physical files of systemDBs
* Run the setup for new version of SQL Server + slipstream the patches to be applied
* Take a copy of physical files of systemDBs again
* Verify the AG setup and check connectivity to SQL instance
* Run full checkdb for databases outside AlwaysOn Availability Groups

**Start the upgrade on the synchronous replica**
* Take a copy of physical files of systemDBs
* Run the setup for new version of SQL Server + slipstream the patches to be applied
* Take a copy of physical files of systemDBs again
* Verify the AG setup and check connectivity to SQL instance
* Run full checkdb for databases outside AlwaysOn Availability Groups

**Start the upgrade on the former primary replica and run checkdb on current primary replica**
* Fail the AG group to the synchronous replica manually
    > Note: that the former primary replica will fail to synchronize past this point and until it is upgraded as well
* Wait until it's done and verify the AG setup (synchronization between current primary and asynchronous secondary replica should start)
* Take a copy of physical files of systemDBson the former primary (current secondary) replica
* Run the setup for new version of SQL Server + slipstream the patches to be applied on the former primary (current secondary) replica
* Take a copy of physical files of systemDBson the former primary (current secondary) replica,
* Run full checkdb for databases outside AlwaysOn Availability Groups
* Resume data movement on the former primary for all databases in the AlwaysOn Availability Groups, wait for the full synchronization please note that in case of non-readable secondary replica you might not be able to resume the data movement experiencing error that database has too low internal version, this can be fixed by running 
    ```sql
    ALTER DATABASE [DBNAME] SET HADR RESUME;
    ```
* Perform a failback to the former primary (current sync secondary)
* Run full checkdb on the synchronous secondary replica
* Run checkdb with physical_only on the primary replica

**General tasks - after implementation steps**
* Change the failover types back to automatic, if applicable
* Verify the AG setup, perform a full backup, check connectivity to SQL instances
 
**Fallback plan**
* Virtual server
    * Restore OS from backup - contact Windows team
* Physical server
    * Failback after/during upgrade of the first replica (secondary asynchronous)
        * Remove the replica from AlwaysOn Availability Group (the group will remain active with two remaining replicas)
        * Get the password for the service account of the SQL instance
        * Uninstall SQL Server on the async secondary
        * Install SQL Server with the former version, patch it to match builds of other replicas in the cluster
        * Join instance to the AlwaysOn Availability Group and add the database to the group via automatic seeding of the database or backup/restore process
    * Failback after/during upgrade of the second replica (secondary synchronous)
        * Repeat steps for sync secondary and then async secondary replicas
        Failback after/during upgrade of the third replica (former primary) – after the first or second failover
        * Repeat steps for former primary replica
        * On the primary restore the databases from the backup before the upgrade
        * Repeat steps for sync and async secondaries 
        * Recreate AlwaysOn Group
 
# FCI instance

**General tasks**
* Verify if full backup is taken successfully, take diff backups
* Change automatic failover types to manual in Failover Cluster Manager
* Start the upgrade on the passive node
    * Take a copy of physical files of systemDBs
    * Run the setup for new version of SQL Server + slipstream the patches to be applied
    * Take a copy of physical files of systemDBs again
    * Reboot the Windows server
    * Repeat steps for all passive nodes
* Start the upgrade on the active node
    * Perform a failover to one of the passive nodes
    * Perform checkdbs with data_purity on the current active node
    * On the former active node Take a copy of physical files of systemDBs
    * Run the setup for new version of SQL Server + slipstream the patches to be applied
    * Take a copy of physical files of systemDBs again
*   Perform a failback, if applicable
 
**After implementation steps**
* Verify that all databases came back online (except for the ones that were offline before the upgrade)
* Run full checkdb against all databases
* Handle possible issues that may arise after checkdb (repair_rebuild/restore from backup)
* Run full backup of all databases
 
**Fallback plan**
* Virtual Server
    * Restore OS from backup - contact Windows team
* Physical Server
    * uninstall the new version of SQL, install the old one
    * Restore SQL databases from backup
 
 
# Other information
**Information about SQL components during an upgrade**
* **Full-Text**: In case of Full-Text choose option "Import", not "Upgrade" - if any action is needed by customer after upgrade they should be aware of it and do it on their own.
* **SSIS**: No option of the upgrade is needed to be chosen - customer should make sure that all SSIS jobs are running fine after the upgrade.
 
# Useful commands
**Backup SMK**
```sql
BACKUP SERVICE MASTER KEY TO FILE = '%filepath%\%instancename%_smk' ENCRYPTION BY PASSWORD = 'xxx' --run at old instance
```

**Restore SMK**
```sql
RESTORE SERVICE MASTER KEY FROM FILE = '%filepath%\%instancename%_smk' DECRYPTION BY PASSWORD = 'xxx' FORCE; --run at new instance
```

**Command to slipstream updates**
```powershell
##Absolute filepath version
d:\sqlinst\SQL2019\SQL2019RTM\Setup.exe /Action=Upgrade /UpdateEnabled=TRUE /UpdateSource=d:\sqlinst\SQL2019\SQL2019RTM\Updates 
 
##Relative filepath version
Setup.exe /Action=Upgrade /UpdateEnabled=TRUE /UpdateSource=.\Updates 
```

**Filepath to Setup Bootstrap**
```
SQL2019: C:\Program Files\Microsoft SQL Server\150\Setup Bootstrap\Log
SQL2017: C:\Program Files\Microsoft SQL Server\140\Setup Bootstrap\Log
SQL2016: C:\Program Files\Microsoft SQL Server\130\Setup Bootstrap\Log
SQL2014: C:\Program Files\Microsoft SQL Server\120\Setup Bootstrap\Log
```

# Downtime estimations
Downtime estimations per each replica in AlwaysOn cluster (primary+sync secondary+async secondary) - rough estimations for personal use: 
* Total (two failovers): 4.25 hour + checkdb + 0.25 hour
* Total (one failover): 4.25 hour
* Asynchronous replica: 3 hours
    * 1 hour - upgrade of asynchronous replica
    * 1.5 hour - upgrade of synchronous replica + 1st failover
    * 0.5 hour - synchronization with former synchronous secondary replica after its 
* Synchronous replica in case of two failovers: 1.50 hour (delayed by ca 1 hour according to downtime of async replica)
    * 1.25 hour - upgrade of synchronous replica + 1st failover
    * 0.25 hour - failback after upgrade of former primary replica and time needed for the synchronization
* Synchronous replica in case of only one failover: 1.25 hour (delayed by ca 1 hour according to downtime of async replica)
    * 1.25 hour - upgrade of synchronous replica + 1st failover
* Primary replica in case of two failovers: 1.50 hour
    * 0.25 hour - failover to former synchronous secondary replica
    * 1 hour - upgrade of the former primary replica
    * 0.25 hour - failover to former primary replica
* Primary replica in case of two failovers: 1.25 hour
    * 0.25 hour - failover to former synchronous secondary replica
    * 1 hour - upgrade of the former primary replica
 
# Further reading
MS Documentation for inplace upgrade of AlwaysOn cluster

https://docs.microsoft.com/en-us/sql/database-engine/availability-groups/windows/upgrading-always-on-availability-group-replica-instances?view=sql-server-ver15
 
MS Documentation for inplace upgrade of WSFC FCI

https://docs.microsoft.com/en-us/sql/sql-server/failover-clusters/windows/upgrade-a-sql-server-failover-cluster-instance?view=sql-server-ver15

