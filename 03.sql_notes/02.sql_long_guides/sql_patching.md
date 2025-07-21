**Author:** Mateusz Wierzbowski

**Created:** 2021/07/16

**Revised:** 2025/07/21

## General consideration:

If you're patching SQL instance with International Service Catalog created, hence with SSISDB created, the database SSISDB will be upgraded during the patching. If it's not updateable, because it's a DR instance and SSISDB is in restoring state, then you need to make it updateable, e.g. recover the database before the patching and you can recreate logshipping for it afterwards again. Otherwise upgrading will fail.

## Preparations:

01. Verify that there are no missing files in installer cache: either using instance_check.ps1 or FileSQLInstalls.vbs or e.g. FixMissingMSI ( https://github.com/suyouquan/SQLSetupTools ) and handle any missing ones - you can use the general script instance_check.ps1

02. Place installation media on the target

03. Verify that password for service account is not expired

## Order of implementation:

01. Multiple standalone instances: perform patching starting from less critical one

02. AlwaysOn: patch all secondary replicas starting from asynchronous one if applicable, fail all AlwaysOn group(s) over to the previously patched replica, patch the former primary replica, fail AlwaysOn group(s) back

03. Failover Cluster Instances: patch all passive nodes, fail instance(s) over to the previously patched node, patch the former active node, fail instance(s) back

## Implementation:

01. Perform diff or log backup of databases

02. Verify state of database, by running

```sql
SELECT name,state_desc,user_access_desc,is_read_only
FROM sys.databases WHERE database_id > 4 ORDER BY database_idRun zip_sys_databases.ps1
```

03. Run the installer

04. Take a backup of system databases

05. Reboot the host

06. Verify that SQL is up, state of databases (script from step 02) and Setup Bootstrap logs

07. Verify connections to SQL

## Fallback plan:

01. Verify Setup Bootstrap logs

02. Uninstall the package from appwiz.cpl

03. Verify that SQL is up and running

04. Verify connections to SQL

## Troubleshooting:

01. If the instance fails to go up after patching, you can bypass the initial upgrade by using Trace Flag T902

## Filepath to Setup Bootstrap:

```txt
SQL2025: C:\Program Files\Microsoft SQL Server\170\Setup Bootstrap\Log
SQL2022: C:\Program Files\Microsoft SQL Server\160\Setup Bootstrap\Log
SQL2019: C:\Program Files\Microsoft SQL Server\150\Setup Bootstrap\Log
SQL2017: C:\Program Files\Microsoft SQL Server\140\Setup Bootstrap\Log
SQL2016: C:\Program Files\Microsoft SQL Server\130\Setup Bootstrap\Log
SQL2014: C:\Program Files\Microsoft SQL Server\120\Setup Bootstrap\Log
```
