/*
Created by: Mateusz Wierzbowski
Creation date: 2020/10/23
Aim: Gather information about services related to SQL, information is retrieved from registry for backward compatibility
Compatibility: SQL2000-SQL2019
*/
--Declare variables
DECLARE
	--registry paths
@reg_path_engine nvarchar (250),@reg_path_agent nvarchar (250),@reg_path_ssas nvarchar (250),@reg_path_ssrs nvarchar (250),@reg_path_ssis nvarchar (250),@reg_path_fdlauncher nvarchar (250)
,@reg_path_sqlbrowser nvarchar (250),@reg_path_sqlwriter nvarchar (250),@reg_path_sqlfulltext nvarchar (250)
	--services
,@engine nvarchar (100),@agent nvarchar (100),@ssas nvarchar (100),@ssrs nvarchar (100),@ssis nvarchar (100),@fdlauncher nvarchar (100),@sql_browser nvarchar (100),@sql_writer nvarchar (100),@sql_fulltext nvarchar (100)
,@engine_start int,@agent_start int,@ssas_start int,@ssrs_start int,@ssis_start int,@fdlauncher_start int,@sql_browser_start int,@sql_writer_start int,@sql_fulltext_start int
 
--Set registry paths
SET @reg_path_sqlbrowser = 'SYSTEM\ControlSet001\Services\SQLBrowser';
SET @reg_path_sqlwriter = 'SYSTEM\ControlSet001\Services\VSS';
SET @reg_path_sqlfulltext = 'SYSTEM\ControlSet001\Services\msftesql';
IF @@SERVICENAME <> 'MSSQLSERVER'
	BEGIN	
		SET @reg_path_engine = 'SYSTEM\ControlSet001\Services\MSSQL$'+ @@SERVICENAME;
		SET @reg_path_agent = 'SYSTEM\ControlSet001\Services\SQLAGENT$'+ @@SERVICENAME;
		SET @reg_path_ssas = 'SYSTEM\ControlSet001\Services\MSOLAP$'+ @@SERVICENAME;
		SET @reg_path_ssrs = 'SYSTEM\ControlSet001\Services\ReportServer$'+ @@SERVICENAME;
		SET @reg_path_fdlauncher = 'SYSTEM\ControlSet001\Services\MSSQLFDLauncher$'+ @@SERVICENAME; END
	ELSE BEGIN	
		SET @reg_path_engine = 'SYSTEM\ControlSet001\Services\MSSQLSERVER';
		SET @reg_path_agent = 'SYSTEM\ControlSet001\Services\SQLSERVERAGENT';
		SET @reg_path_ssas = 'SYSTEM\ControlSet001\Services\MSSQLServerOLAPService';
		SET @reg_path_ssrs = 'SYSTEM\ControlSet001\Services\ReportServer';
		SET @reg_path_fdlauncher = 'SYSTEM\ControlSet001\Services\MSSQLFDLauncher';	
	END
IF CONVERT(varchar(40),SERVERPROPERTY('ProductVersion')) LIKE '9%'
	BEGIN SET @reg_path_ssis = 'SYSTEM\ControlSet001\Services\MsDtsServer'; END
	ELSE IF CONVERT(varchar(40),SERVERPROPERTY('ProductVersion')) LIKE '10%'
		BEGIN SET @reg_path_ssis = 'SYSTEM\ControlSet001\Services\MsDtsServer100'; END
	ELSE IF CONVERT(varchar(40),SERVERPROPERTY('ProductVersion')) LIKE '11%'
		BEGIN SET @reg_path_ssis = 'SYSTEM\ControlSet001\Services\MsDtsServer110'; END
	ELSE IF CONVERT(varchar(40),SERVERPROPERTY('ProductVersion')) LIKE '12%'
		BEGIN SET @reg_path_ssis = 'SYSTEM\ControlSet001\Services\MsDtsServer120'; END
	ELSE IF CONVERT(varchar(40),SERVERPROPERTY('ProductVersion')) LIKE '13%'
		BEGIN SET @reg_path_ssis = 'SYSTEM\ControlSet001\Services\MsDtsServer130'; END
	ELSE IF CONVERT(varchar(40),SERVERPROPERTY('ProductVersion')) LIKE '14%'
		BEGIN SET @reg_path_ssis = 'SYSTEM\ControlSet001\Services\MsDtsServer140'; END
	ELSE IF CONVERT(varchar(40),SERVERPROPERTY('ProductVersion')) LIKE '15%'
		BEGIN SET @reg_path_ssis = 'SYSTEM\ControlSet001\Services\MsDtsServer150'; END
--Check values
exec [master].dbo.xp_regread N'HKEY_LOCAL_MACHINE', @reg_path_engine, N'ObjectName', @engine output, 'no_output'	
	exec [master].dbo.xp_regread N'HKEY_LOCAL_MACHINE', @reg_path_engine, N'Start', @engine_start output, 'no_output'	
exec [master].dbo.xp_regread N'HKEY_LOCAL_MACHINE', @reg_path_agent, N'ObjectName', @agent output, 'no_output'	
	exec [master].dbo.xp_regread N'HKEY_LOCAL_MACHINE', @reg_path_agent, N'Start', @agent_start output, 'no_output'
exec [master].dbo.xp_regread N'HKEY_LOCAL_MACHINE', @reg_path_ssas, N'ObjectName', @ssas output, 'no_output'	
	exec [master].dbo.xp_regread N'HKEY_LOCAL_MACHINE', @reg_path_ssas, N'Start', @ssas_start output, 'no_output'
exec [master].dbo.xp_regread N'HKEY_LOCAL_MACHINE', @reg_path_ssrs, N'ObjectName', @ssrs output, 'no_output'
	exec [master].dbo.xp_regread N'HKEY_LOCAL_MACHINE', @reg_path_ssrs, N'Start', @ssrs_start output, 'no_output'	
exec [master].dbo.xp_regread N'HKEY_LOCAL_MACHINE', @reg_path_ssis, N'ObjectName', @ssis output, 'no_output'
	exec [master].dbo.xp_regread N'HKEY_LOCAL_MACHINE', @reg_path_ssis, N'Start', @ssis_start output, 'no_output'
exec [master].dbo.xp_regread N'HKEY_LOCAL_MACHINE', @reg_path_fdlauncher, N'ObjectName', @fdlauncher output, 'no_output'
	exec [master].dbo.xp_regread N'HKEY_LOCAL_MACHINE', @reg_path_fdlauncher, N'Start', @fdlauncher_start output, 'no_output'
exec [master].dbo.xp_regread N'HKEY_LOCAL_MACHINE', @reg_path_sqlbrowser, N'ObjectName', @sql_browser output, 'no_output'
	exec [master].dbo.xp_regread N'HKEY_LOCAL_MACHINE', @reg_path_sqlbrowser, N'Start', @sql_browser_start output, 'no_output'
exec [master].dbo.xp_regread N'HKEY_LOCAL_MACHINE', @reg_path_sqlwriter, N'ObjectName', @sql_writer output, 'no_output'
	exec [master].dbo.xp_regread N'HKEY_LOCAL_MACHINE', @reg_path_sqlwriter, N'Start', @sql_writer_start output, 'no_output'
exec [master].dbo.xp_regread N'HKEY_LOCAL_MACHINE', @reg_path_sqlfulltext, N'ObjectName', @sql_fulltext output, 'no_output'	
	exec [master].dbo.xp_regread N'HKEY_LOCAL_MACHINE', @reg_path_sqlfulltext, N'Start', @sql_fulltext_start output, 'no_output'
 
SELECT
	@engine AS sql_acc
	,CASE @engine_start
		WHEN 1 THEN 'System'
		WHEN 2 THEN 'Automatic'
		WHEN 3 THEN 'Manual'
		WHEN 4 THEN 'Disabled'
		ELSE NULL
	END AS sql_startup
	,@agent AS agent_acc
	,CASE @agent_start
		WHEN 1 THEN 'System'
		WHEN 2 THEN 'Automatic'
		WHEN 3 THEN 'Manual'
		WHEN 4 THEN 'Disabled'
		ELSE NULL
	END AS agent_startup
	,@ssas AS ssas_acc
	,CASE @ssas_start
		WHEN 1 THEN 'System'
		WHEN 2 THEN 'Automatic'
		WHEN 3 THEN 'Manual'
		WHEN 4 THEN 'Disabled'
		ELSE NULL
	END AS ssas_startup
	,@ssrs AS ssrs_acc
	,CASE @ssrs_start
		WHEN 1 THEN 'System'
		WHEN 2 THEN 'Automatic'
		WHEN 3 THEN 'Manual'
		WHEN 4 THEN 'Disabled'
		ELSE NULL
	END AS ssrs_startup
	,@ssis AS ssis_acc
	,CASE @ssis_start
		WHEN 1 THEN 'System'
		WHEN 2 THEN 'Automatic'
		WHEN 3 THEN 'Manual'
		WHEN 4 THEN 'Disabled'
		ELSE NULL
	END AS ssis_startup
	,@fdlauncher AS fd_launcher_acc
	,CASE @fdlauncher_start
		WHEN 1 THEN 'System'
		WHEN 2 THEN 'Automatic'
		WHEN 3 THEN 'Manual'
		WHEN 4 THEN 'Disabled'
		ELSE NULL
	END AS fd_launcher_startup
	,@sql_browser AS sql_browser_acc
	,CASE @sql_browser_start
		WHEN 1 THEN 'System'
		WHEN 2 THEN 'Automatic'
		WHEN 3 THEN 'Manual'
		WHEN 4 THEN 'Disabled'
		ELSE NULL
	END AS sql_browser_startup
	,@sql_writer AS sql_writer_acc
	,CASE @sql_writer_start
		WHEN 1 THEN 'System'
		WHEN 2 THEN 'Automatic'
		WHEN 3 THEN 'Manual'
		WHEN 4 THEN 'Disabled'
		ELSE NULL
	END AS sql_writer_startup
	,@sql_fulltext AS sql_fulltext_acc
	,CASE @sql_fulltext_start
		WHEN 1 THEN 'System'
		WHEN 2 THEN 'Automatic'
		WHEN 3 THEN 'Manual'
		WHEN 4 THEN 'Disabled'
		ELSE NULL
	END AS sql_fulltext_startup;
