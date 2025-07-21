/*
Created by: Mateusz Wierzbowski
Creation date: 2019/03/25
Aim: Enforce password policy for each SQL login that still doesn't have it enforced
Verified on: SQL 2014
Updates: 2021/10/03 - rewritten in snake_case notation
*/
USE tempdb;
SET NOCOUNT ON;
 
--Check SQL logins before implementation
SELECT
	[name]
	,is_policy_checked
FROM sys.sql_logins
WHERE is_disabled =0 AND is_policy_checked = 0;
 
--First part of query: Backup master DB in default backup location
IF OBJECT_ID('#dba_force_pass_policy','U') IS NOT NULL BEGIN DROP TABLE [#dba_force_pass_policy]; END
 
DECLARE @backuppath varchar(500), @query nvarchar(2000);
 
CREATE TABLE #dba_force_pass_policy (
	[value] varchar(100)
	,[data] varchar(500)
)
INSERT INTO #dba_force_pass_policy
exec [master].dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\MSSQLServer', N'BackupDirectory';
 
SET @backuppath = (SELECT Data FROM #dba_force_pass_policy)
SET @query = ('BACKUP DATABASE [master] TO DISK = N'''+@backuppath+'\masterDB_before_enforcing_passwordpolicy.bak'' WITH COPY_ONLY, NOFORMAT, NOINIT, NAME = N''master-Full Database Backup'', SKIP, NOREWIND, NOUNLOAD, STATS = 10')
exec sp_sqlexec @query;
 
DROP TABLE #dba_force_pass_policy;
 
--Second part of query: enforce password policy
DECLARE @login_temp sysname, @db_name sysname, @lang sysname, @query2 nvarchar(2000);
 
DECLARE login_crsr CURSOR FOR
SELECT [name]
FROM sys.sql_logins
WHERE is_disabled = 0 AND is_policy_checked = 0;
 
OPEN login_crsr;
	FETCH NEXT FROM login_crsr INTO @login_temp
		WHILE @@FETCH_STATUS = 0
			BEGIN
				SET @db_name = (SELECT default_database_name FROM sys.sql_logins WHERE [name] = @login_temp)
				SET @lang = (SELECT default_language_name FROM sys.sql_logins WHERE [name] = @login_temp)
				SET @query2 = ('USE [master]; ALTER LOGIN ['+@login_temp+'] WITH DEFAULT_DATABASE=['+@db_name+'], DEFAULT_LANGUAGE=['+@lang+'], CHECK_EXPIRATION=OFF, CHECK_POLICY=ON')
				exec sp_sqlexec @query2;
				FETCH NEXT FROM login_crsr INTO @login_temp
			END
CLOSE login_crsr
DEALLOCATE login_crsr
--Check SQL logins after implementation
SELECT
	[name]
	,is_policy_checked
FROM sys.sql_logins
WHERE 1=1 
	AND is_disabled = 0 
	AND is_policy_checked = 0;
