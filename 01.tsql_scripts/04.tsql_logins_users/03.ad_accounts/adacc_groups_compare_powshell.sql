/*
Author: Mateusz Wierzbowski
Creation date: 2020/03/01-05
Aim: Gather information about AG groups of DBAs in a domain from DIMS via Get-ADPrincipalGroupMembership
Corrections:
	2020/03/29 - corrected datatypes for tables and @line to (max)
*/
USE tempdb;
SET NOCOUNT ON;
 
--Cleanup old tables
IF OBJECT_ID('#dba_ad_accounts','U') IS NOT NULL BEGIN DROP TABLE #dba_ad_accounts; END
IF OBJECT_ID('#dba_ad_xp','U') IS NOT NULL BEGIN DROP TABLE #dba_ad_xp; END
IF OBJECT_ID('#dba_ad_acc_group','U') IS NOT NULL BEGIN DROP TABLE #dba_ad_acc_group; END
IF OBJECT_ID('#dba_ad_group','U') IS NOT NULL BEGIN DROP TABLE #dba_ad_group; END
 
--Declare variables
DECLARE @ad_prefix varchar(20), @line varchar(max), @ad_groups_no int, @ad_acc varchar(50), @query1 varchar(500);
 
--Create new tables
CREATE TABLE #dba_ad_accounts (
	account varchar(20)
);
CREATE TABLE #dba_ad_xp (
	[line] varchar(max)
);
CREATE TABLE #dba_ad_acc_group (
	ad_account varchar(50)
	,ad_group varchar(max)
);
CREATE TABLE #dba_ad_group (
	ad_group varchar(max)
);
	/* First part of wrapper */
	DECLARE @v_cmdshell sql_variant, @v_advanced_options sql_variant;
	SELECT @v_advanced_options = [value] FROM sys.configurations WHERE name = 'show advanced options';
	SELECT @v_cmdshell = [value] FROM sys.configurations WHERE name = 'xp_cmdshell';
	IF @v_cmdshell = 0
	BEGIN
		IF @v_advanced_options = 0
			BEGIN
				exec sp_configure 'show advanced options', 1;
				RECONFIGURE;
				exec sp_configure 'xp_cmdshell', 1;
				RECONFIGURE;
			END
		ELSE
			BEGIN
				exec sp_configure 'xp_cmdshell', 1;
				RECONFIGURE;
			END
	END
	/* End of first part of wrapper */
 

/* ACTUAL QUERY */
 
/*PART WHERE YOU NEED TO PROVIDE PARAMS*/
--Declare a prefix of AD user accounts
SET @ad_prefix = ''; --include hyphen if applicable, examples: ADMIN, admin-
--Choose DBAs for a check
INSERT INTO #dba_ad_accounts
VALUES ('account_name_01'),('account_name_02'),('account_name_03'),('account_name_04');
 

/*DO NOT CHANGE THE QUERY BELOW*/
DECLARE acc_crsr CURSOR LOCAL FAST_FORWARD FOR
SELECT account FROM #dba_ad_accounts;
--Run a cursor for each DBA
OPEN acc_crsr;
FETCH NEXT FROM acc_crsr INTO @ad_acc
WHILE @@FETCH_STATUS = 0
BEGIN
 
	--Query domain controller
	SET @query1 = 'exec master..xp_cmdshell ''powershell "Get-ADPrincipalGroupMembership '+@ad_prefix+@ad_acc+' | select name" '' ';
	INSERT INTO #dba_ad_xp
	exec (@query1);
 
	--Include data about AD user and AD groups only
	INSERT INTO #dba_ad_acc_group
	SELECT @ad_acc, * FROM #dba_ad_xp WHERE [line] NOT LIKE '%name%' AND [line] NOT LIKE '%----%' AND [line] IS NOT NULL;
	--Get unrefined list of AD groups into one variable per DBA
	TRUNCATE TABLE #dba_ad_xp;
	--Add column into the final table for each DBA
	SET @query1 = 'ALTER TABLE #dba_ad_group ADD '+@ad_acc+' varchar(20);';
	exec (@query1);
	--Insert AD group into final date, if it's not there yet, and mark the account as existing
	SET @query1 = 'INSERT INTO #dba_ad_group (ad_group,'+@ad_acc+')
	SELECT DISTINCT(ad_group),1 FROM #dba_ad_acc_group
	WHERE ad_group NOT IN (SELECT ad_group FROM #dba_ad_group)';
	exec (@query1);
	--Mark account as existing if AD group is already mentioned in the final table
	SET @query1 = 'UPDATE #dba_ad_group
	SET '+@ad_acc+' = 1
	WHERE ad_group IN (SELECT ad_group FROM #dba_ad_acc_group) AND ad_group IN (SELECT ad_group FROM #dba_ad_group)'
	exec (@query1);
	TRUNCATE TABLE #dba_ad_acc_group;
 
--Fetch next DBA into table
FETCH NEXT FROM acc_crsr INTO @ad_acc;
--Close the cursor
END
CLOSE acc_crsr;
DEALLOCATE acc_crsr;
 
--Get final result
SELECT * FROM #dba_ad_group;
 
--Cleanup
DROP TABLE #dba_ad_accounts;
DROP TABLE #dba_ad_xp;
DROP TABLE #dba_ad_acc_group;
DROP TABLE #dba_ad_group;
 
	/* Second part of wrapper */
	IF @v_cmdshell = 0
	BEGIN
		IF @v_advanced_options = 0
			BEGIN
				exec sp_configure 'xp_cmdshell', 0;
				RECONFIGURE;
				exec sp_configure 'show advanced options', 0;
				RECONFIGURE;
			END
		ELSE
			BEGIN
				exec sp_configure 'xp_cmdshell', 0;
				RECONFIGURE;
			END
	END
	/* End of wrapper */
