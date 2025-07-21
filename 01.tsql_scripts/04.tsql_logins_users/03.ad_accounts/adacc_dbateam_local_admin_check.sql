/*
Created by: Mateusz Wierzbowski
Creation date: 2019/07/04
Aim: Check if any AD group that grants DBA team sysadmin on OS level
If query doesn't return any row it means that no AD group exists on OS and DBA Team doesn't have sysadmin rights on OS
Change the name of AD groups that you want to check in line 39 from ADGroupforDBAs
*/
USE tempdb;
SET NOCOUNT ON;
 
IF OBJECT_ID('#dba_admin_check','U') IS NOT NULL BEGIN DROP TABLE #dba_admin_check; END
CREATE TABLE #dba_admin_check (
	[line] nvarchar(2000)
);
 
	/* First part of wrapper */
	DECLARE @v_cmdshell sql_variant, @v_advanced_options sql_variant;
	SELECT @v_advanced_options = [value] FROM sys.configurations WHERE [name] = 'show advanced options';
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
 
INSERT INTO #dba_admin_check
	exec [master].dbo.xp_cmdshell 'net localgroup administrators';
 
SELECT
	[line]
FROM #dba_admin_check
WHERE [line] LIKE '%ADGroupforDBAs%'
 
DROP TABLE #dba_admin_check;
 
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
