/*
Created by: Mateusz Wierzbowski
Creation date: 2020/10/29-30
Aim: Gather information about SQL instance configuration according to SQL best practices by MTPW and preparing scripts for reconfiguring a number of them
*/
SET NOCOUNT ON;
--Step 01: Declare variables
DECLARE @v01 nvarchar(10), @v02 nvarchar(10), @v03 nvarchar(2000), @v04 nvarchar(2000), @v05 nvarchar(2000), @v06 nvarchar(2000), @v07 nvarchar(2000)
	, @v08 nvarchar(2000), @v09 nvarchar(2000), @v10 VARCHAR(100), @v11 nvarchar(2000), @v12 nvarchar(2000)
	, @adv_opt sql_variant, @os_ram int, @new_max int, @curr_max nvarchar(20), @curr_min nvarchar(20)
	, @index_fill int, @bck_comp int, @ctp int, @curr_dop int, @core_count int, @max_dop int, @tmp_files int, @adhoc int
	, @sa_name sysname, @sa_state int, @clr int, @dbmail int, @dac int, @remote int
	, @inst_name nvarchar(100), @reg_path_np varchar (350), @reg_path_via varchar(350), @np_status int, @via_status int, @static_port nvarchar(10);
 
IF OBJECT_ID('#dba_guest_acc','U') IS NOT NULL BEGIN DROP TABLE #dba_guest_acc; END
IF OBJECT_ID('#dba_dbcc','U') IS NOT NULL BEGIN DROP TABLE #dba_dbcc; END
IF OBJECT_ID('#dba_xp','U') IS NOT NULL BEGIN DROP TABLE #dba_xp; END
IF OBJECT_ID('#dba_instances_xp','U') IS NOT NULL BEGIN DROP TABLE #dba_instances_xp; END
IF OBJECT_ID('#dba_perc','U') IS NOT NULL BEGIN DROP TABLE #dba_perc; END
 
CREATE TABLE #dba_guest_acc (
	[name] sysname
);
CREATE TABLE #dba_dbcc (
	trace_flag nvarchar(20)
	,[status] int
	,[global] int
	,[session] int
);
CREATE TABLE #dba_xp (
	ID int IDENTITY(1,1)
	,[line] varchar(8000)
);
CREATE TABLE #dba_instances_xp (
	[line] nvarchar(200) NULL
);
CREATE TABLE #dba_perc (
	[name] sysname
);
 
SELECT @adv_opt = [value] FROM sys.configurations WHERE [name] = 'show advanced options'
 
--Step 02: Gather info about OS RAM and SQL memory settings
SELECT @os_ram = physical_memory_kb/(1024*1024) FROM sys.dm_os_sys_info;
SELECT @new_max = CASE
	WHEN @os_ram > 16 THEN @os_ram-2-4-CEILING((@os_ram-16)/8.0)
	ELSE @os_ram-2-CEILING(@os_ram/4.0)
	END
SELECT @curr_min = [value] FROM sys.sysconfigures WHERE comment = 'Minimum size of server memory (MB)';
SELECT @curr_max = [value] FROM sys.sysconfigures WHERE comment = 'Maximum size of server memory (MB)';
 
--Step 03: Check if there are different SQL instances on the server
	--Step 03.01: declare variables
DECLARE @cmd sql_variant, @ps nvarchar(50);
SELECT @cmd = [value] FROM sys.configurations WHERE [name] = 'xp_cmdshell';
	--Step 03.02: enable xp_cmdshell if it's disabled
IF @cmd = 0
BEGIN
	IF @adv_opt = 0 BEGIN exec sp_configure 'show advanced options', 1; RECONFIGURE; exec sp_configure 'xp_cmdshell', 1; RECONFIGURE; END
	ELSE BEGIN exec sp_configure 'xp_cmdshell', 1; RECONFIGURE; END
END
	--Step 03.03: change PS ExecutionPolicy to Unrestricted if it's Restricted
 
INSERT INTO #dba_xp
	exec [master].dbo.xp_cmdshell 'powershell Get-ExecutionPolicy';
SET @ps = (SELECT TOP (1) [line] FROM #dba_xp WHERE [line] IS NOT NULL ORDER BY ID desc);
 
IF @ps = 'Restricted'
	BEGIN exec master..xp_cmdshell 'powershell Set-ExecutionPolicy Unrestricted', no_output; END
 
	--Step 03.04: check if there are other SQL instances on the server
INSERT INTO #dba_instances_xp
	exec xp_cmdshell 'powershell "Get-Service *SQL*"'
SELECT @v01 = COUNT(*)-1 FROM #dba_instances_xp WHERE [line] IS NOT NULL AND [line] LIKE '%SQL Server (%';
SELECT @v02 = COUNT(*) FROM #dba_instances_xp WHERE [line] IS NOT NULL AND [line] LIKE '%Running%Browser%';
 
	--Step 03.05: change ExecutionPolicy back to Restricted
IF @ps = 'Restricted'
	BEGIN exec [master].dbo.xp_cmdshell 'powershell Set-ExecutionPolicy Restricted', no_output; END
 
	--Step 03.06: if xp_cmdshell had been disabled, disable it again
IF @cmd = 0 BEGIN
	IF @adv_opt = 0
		BEGIN exec sp_configure 'xp_cmdshell', 0; RECONFIGURE; exec sp_configure 'show advanced options', 0; RECONFIGURE; END
	ELSE
		BEGIN exec sp_configure 'xp_cmdshell', 0; RECONFIGURE; END
END
 
--Step 04: check sys.configurations and sys.dm_os_nodes about needed values
SELECT @index_fill = [value] FROM sys.sysconfigures WHERE comment = 'default fill factor percentage';
SELECT @bck_comp = [value] FROM sys.sysconfigures WHERE comment = 'enable compression of backups by default';
SELECT @ctp = [value] FROM sys.sysconfigures WHERE comment = 'cost threshold for parallelism';
SELECT @curr_dop = [value] FROM sys.sysconfigures WHERE comment = 'maximum degree of parallelism';
SELECT @core_count = SUM(online_scheduler_count) FROM sys.dm_os_nodes WHERE node_state_desc <> N'ONLINE DAC';
SELECT @max_dop = MAX(online_scheduler_count) FROM sys.dm_os_nodes WHERE node_state_desc <> N'ONLINE DAC';
	SET @max_dop = CASE WHEN @max_dop > 8 THEN 8 ELSE @max_dop END;
SELECT @adhoc = [value] FROM sys.sysconfigures WHERE comment = 'enable or disable ad hoc distributed queries';
SELECT @clr = [value] FROM sys.sysconfigures WHERE comment = 'clr user code execution enabled in the server';
SELECT @dbmail = [value] FROM sys.sysconfigures WHERE comment = 'enable or disable database mail xps';
SELECT @dac = [value] FROM sys.sysconfigures WHERE comment = 'dedicated admin connections are allowed from remote clients';
SELECT @remote = [value] FROM sys.sysconfigures WHERE comment = 'allow remote access';
 

--Step 05: check sys.master_files for needed values
SELECT @tmp_files = COUNT(*) FROM sys.master_files WHERE database_id = 2 AND [type] = 0;
INSERT INTO @perc
SELECT DISTINCT DB_NAME(database_id) FROM sys.master_files WHERE is_percent_growth = 1;
	SET @v03 = '';
	SELECT @v03 = @v03 + ', ' + [name] from @perc
	SELECT @v03 = CASE WHEN @v03 = '' THEN '' ELSE SUBSTRING(@v03,3,LEN(@v03)-2) END;
 
--Step 06: check sys.databases for needed values
SET @v04 = '';
	SELECT @v04 = @v04 + ', ' + [name] FROM sys.databases WHERE is_auto_close_on = 1;
	SELECT @v04 = CASE WHEN @v04 = '' THEN '' ELSE SUBSTRING(@v04,3,LEN(@v04)-2) END;
SET @v05 = '';
	SELECT @v05 = @v05 + ', ' + [name] FROM sys.databases WHERE is_auto_create_stats_on = 0;
	SELECT @v05 = CASE WHEN @v05 = '' THEN '' ELSE SUBSTRING(@v05,3,LEN(@v05)-2) END;
SET @v06 = '';
	SELECT @v06 = @v06 + ', ' + [name] FROM sys.databases WHERE is_auto_update_stats_on = 0;
	SELECT @v06 = CASE WHEN @v06 = '' THEN '' ELSE SUBSTRING(@v06,3,LEN(@v06)-2) END;
SET @v07 = '';
	SELECT @v07 = @v07 + ', ' + [name] FROM sys.databases WHERE is_auto_shrink_on = 1;
	SELECT @v07 = CASE WHEN @v07 = '' THEN '' ELSE SUBSTRING(@v07,3,LEN(@v07)-2) END;
SET @v08 = '';
	SELECT @v08 = @v08 + ', ' + [name] FROM sys.databases WHERE is_parameterization_forced = 0;
	SELECT @v08 = CASE WHEN @v08 = '' THEN '' ELSE SUBSTRING(@v08,3,LEN(@v08)-2) END;
SET @v09 = '';
	SELECT @v09 = @v09 + ', ' + [name] FROM sys.databases WHERE is_trustworthy_on = 1 AND database_id <> 4;
	SELECT @v09 = CASE WHEN @v09 = '' THEN '' ELSE SUBSTRING(@v09,3,LEN(@v09)-2) END;
 
--Step 07: check sys.server_principals for needed values
SELECT @sa_name = [name] FROM sys.server_principals WHERE [sid] = 0x01;
SELECT @sa_state = is_disabled FROM sys.server_principals WHERE [sid] = 0x01;
 
--Step 08: check registry for needed values
SET @inst_name=CONVERT(nvarchar,ISNULL(SERVERPROPERTY('INSTANCENAME'),'MSSQLSERVER'));
	exec [master].dbo.xp_regread N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL', @inst_name, @v10 OUTPUT;
SET @reg_path_np = 'SOFTWARE\Microsoft\Microsoft SQL Server\' + @v10 + '\MSSQLServer\SuperSocketNetLib\Np' ;
	exec [master].dbo.xp_regread N'HKEY_LOCAL_MACHINE', @reg_path_np, N'Enabled', @np_status output, 'no_output' ;
SET @reg_path_via = 'SOFTWARE\Microsoft\Microsoft SQL Server\' + @v10 + '\MSSQLServer\SuperSocketNetLib\Via';
	exec [master].dbo.xp_regread N'HKEY_LOCAL_MACHINE', @reg_path_via, N'Enabled', @via_status output, 'no_output';
exec [master].dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\Microsoft SQL Server\MSSQLServer\SuperSocketNetLib\Tcp\IpAll', N'TcpPort', @static_port output, 'no_output';
 
--Step 09: check guest accounts
exec sp_MSforeachdb 'use ?
INSERT INTO #dba_guest_acc
SELECT DB_NAME() FROM sys.sysusers WHERE [name] = ''guest'' and hasdbaccess = 1 ';
 
SET @v11 = '';
	SELECT @v11 = @v11 + ', ' + [name] FROM #dba_guest_acc WHERE [name] <> 'master' AND [name] <> 'msdb' AND [name] <> 'tempdb';
	SELECT @v11 = CASE WHEN @v11 = '' THEN '' ELSE SUBSTRING(@v11,3,LEN(@v11)-2) END;
 
--Step 10: check trace flags
INSERT INTO #dba_dbcc
exec ('dbcc tracestatus(-1) WITH NO_INFOMSGS')
SET @v12 = '';
	SELECT @v12 = @v12 + ', ' + trace_flag FROM #dba_dbcc;
	SELECT @v12 = CASE WHEN @v12 = '' THEN '' ELSE SUBSTRING(@v12,3,LEN(@v12)-2) END;
 
--Step 11: Drop tables
DROP TABLE #dba_guest_acc;
DROP TABLE #dba_dbcc;
DROP TABLE #dba_xp;
DROP TABLE #dba_instances_xp;
DROP TABLE #dba_perc;
 
--Step 12:Gather all details
PRINT N'--Checking memory settings:'
PRINT N'--System has '+CAST(@os_ram AS NVARCHAR(20))+' GB of RAM'
PRINT N'--SQL Server has '+@curr_min+' MB of minimum memory'
IF @curr_min < 500
	BEGIN PRINT N'--Consider changing it with following command:'+CHAR(13)+'exec sp_configure ''show advanced options'', 1;'+CHAR(13)+'RECONFIGURE WITH OVERRIDE;'+CHAR(13)+
	'exec sys.sp_configure N''min server memory (MB)'', N''500'';'+CHAR(13)+'GO'+CHAR(13)+
	'RECONFIGURE WITH OVERRIDE;'+CHAR(13)+'GO'+CHAR(13) END
PRINT N'--SQL Server has '+@curr_max+' MB of max server memory'
PRINT N'--Optimal maximum server memory is '+CAST(@new_max*1024 AS nvarchar(20))+' MB or '+CAST(@new_max AS nvarchar(20))+' GB'
IF @curr_max < @new_max*1024
	BEGIN PRINT N'--Consider changing it with following command:'+CHAR(13)+'exec sp_configure ''show advanced options'', 1;'+CHAR(13)+'RECONFIGURE WITH OVERRIDE;'+CHAR(13)+
	'exec sys.sp_configure N''max server memory (MB)'', N'''+CAST(@new_max*1024 AS nvarchar(20))+''';'+CHAR(13)+'GO'+CHAR(13)
		+'RECONFIGURE WITH OVERRIDE;;'+CHAR(13)+'GO' END
IF @v01 > 0
	BEGIN PRINT N'--**Please be aware that on this server there''s also '+@v01+' other instance(s)' END
PRINT CHAR(13)+N'--Default index fill factor is set to: '+CAST(@index_fill AS nvarchar(20))
IF @index_fill < 90
	BEGIN PRINT N'--Consider changing it to 90 with following command:'+CHAR(13)+'exec sp_configure ''show advanced options'', 1;'+CHAR(13)+'RECONFIGURE WITH OVERRIDE;'+CHAR(13)+
	'exec sys.sp_configure N''fill factor'', 90;'+CHAR(13)+'RECONFIGURE;'; END
PRINT CHAR(13)+N'--Default backup compression is '+CASE WHEN @bck_comp = 1 THEN 'ENABLED' ELSE 'DISABLED' END
IF @bck_comp = 0
	BEGIN PRINT N'--Consider enabling it with following command:'+CHAR(13)+'exec sys.sp_configure N''backup compression default'',1;'+CHAR(13)+'RECONFIGURE;'; END
PRINT CHAR(13)+N'--Cost Threshold for Parallelism (CTP) is set to: '+CAST(@ctp AS nvarchar(20))
IF @ctp < 25
	BEGIN PRINT N'--Consider changing it to 40 with following command:'+CHAR(13)+'exec sp_configure ''show advanced options'', 1;'+CHAR(13)+'RECONFIGURE WITH OVERRIDE;'+CHAR(13)+
	'exec sys.sp_configure N''cost threshold for parallelism'', 40;'+CHAR(13)+'RECONFIGURE;' END
PRINT CHAR(13)+N'--Max Degree of Parallelism is set to: '+CAST(@curr_dop AS nvarchar(20))
IF @curr_dop < @max_dop
	BEGIN PRINT N'--Consider changing it to '+CAST(@max_dop AS nvarchar(20))+' with following command:'+CHAR(13)+'exec sp_configure ''show advanced options'', 1;'+CHAR(13)+'RECONFIGURE WITH OVERRIDE;'+CHAR(13)+
	'exec sys.sp_configure N''max degree of parallelism'', '+CAST(@max_dop AS nvarchar(20))+';'+CHAR(13)+'RECONFIGURE;' END
PRINT CHAR(13)+N'--SQL Instance has '+CAST(@tmp_files AS nvarchar(20))+' TempDB files and '+CAST(@core_count AS nvarchar(20))+' CPU cores'
	SET @core_count = CASE WHEN @core_count > 8 THEN 8 ELSE @core_count END
IF @tmp_files < 8 AND @tmp_files < @core_count
	BEGIN PRINT N'--Consider changing it to '+CAST(@Core_Count AS nvarchar(20))+' TempDB files' END
PRINT CHAR(13)+N'--Ad hoc distributed queries are '+CASE WHEN @adhoc = 1 THEN 'ENABLED' ELSE 'DISABLED' END
IF @adhoc = 0
	BEGIN PRINT N'--Consider enabling them with following command:'+CHAR(13)+'exec sp_configure ''show advanced options'', 1;'+CHAR(13)+'RECONFIGURE WITH OVERRIDE;'+CHAR(13)+
	'exec sys.sp_configure N''ad hoc distributed queries'',1;'+CHAR(13)+'RECONFIGURE;' END
IF @v03 <> ''
	BEGIN PRINT CHAR(13)+N'--Following databases have autogrowth set to a percentage instead of MB: '
	PRINT N'--'+@v03
	PRINT N'--Consider changing it to MB value' END
	ELSE BEGIN PRINT CHAR(13)+N'--None database has autogrowth set to a percentage' END
IF @v04 <> ''
	BEGIN PRINT CHAR(13)+N'--Following databases have autoclose enabled: '
	PRINT N'--'+@v04
	PRINT N'--Consider disabling it' END
	ELSE BEGIN PRINT CHAR(13)+N'--None database has autoclose enabled' END
IF @v05 <> ''
	BEGIN PRINT CHAR(13)+N'--Following databases have auto create statistics disabled: '
	PRINT N'--'+@v05
	PRINT N'--Consider enabling it' END
	ELSE BEGIN PRINT CHAR(13)+N'--None database has auto create statistics disabled' END
IF @v06 <> ''
	BEGIN PRINT CHAR(13)+N'--Following databases have auto update statistics disabled: '
	PRINT N'--'+@v06
	PRINT N'--Consider enabling it' END
	ELSE BEGIN PRINT CHAR(13)+N'--None database has auto update statistics disabled' END
IF @v07 <> ''
	BEGIN PRINT CHAR(13)+N'--Following databases have auto shrink enabled: '
	PRINT N'--'+@v07
	PRINT N'--Consider disabling it' END
	ELSE BEGIN PRINT CHAR(13)+N'--None database has auto shrink enabled' END
IF @v08 <> ''
	BEGIN PRINT CHAR(13)+N'--Following databases have forced parametrization disabled: '
	PRINT N'--'+@v08
	PRINT N'--Consider enabling it' END
	ELSE BEGIN PRINT CHAR(13)+N'--None database has forced parametrization enabled' END
IF @v09 <> ''
	BEGIN PRINT CHAR(13)+N'--Following databases (except for msdb) have trustworthiness enabled: '
	PRINT N'--'+@v09
	PRINT N'--Consider disabling it' END
	ELSE BEGIN PRINT CHAR(13)+N'--None database (except for msdb) has trustworthiness enabled' END
IF @sa_name = 'sa'
	BEGIN PRINT CHAR(13)+N'--Default [sa] login hasn''t been renamed. Consider renaming it' END
	ELSE BEGIN PRINT CHAR(13)+N'--Default [sa] login has been renamed to '+@sa_name+'. No further action needed' END
IF @sa_state = 0
	BEGIN PRINT CHAR(13)+N'--Default [sa] login hasn''t been disabled. Consider disabling it' END
	ELSE BEGIN PRINT CHAR(13)+N'--Default [sa] login has been disabled. No further action needed' END
PRINT CHAR(13)+N'--CLR integration is '+CASE WHEN @clr = 1 THEN 'ENABLED' ELSE 'DISABLED' END
IF @clr = 1
	BEGIN PRINT N'--Consider disabling them with following command:'+CHAR(13)+'exec sp_configure ''show advanced options'', 1;'+CHAR(13)+'RECONFIGURE WITH OVERRIDE;'+CHAR(13)+
	'exec sys.sp_configure N''clr enabled'',0;'+CHAR(13)+'RECONFIGURE;'; END
PRINT CHAR(13)+N'--CmdShell is '+CASE WHEN @cmd = 1 THEN 'ENABLED' ELSE 'DISABLED' END
IF @cmd = 1
	BEGIN PRINT N'--Consider disabling them with following command:'+CHAR(13)+'exec sp_configure ''show advanced options'', 1;'+CHAR(13)+'RECONFIGURE WITH OVERRIDE;'+CHAR(13)+
	'exec sys.sp_configure N''xp_cmdshell'',0;'+CHAR(13)+'RECONFIGURE;'; END
PRINT CHAR(13)+N'--DBMail is '+CASE WHEN @dbmail = 1 THEN 'ENABLED' ELSE 'DISABLED' END
IF @dbmail = 1
	BEGIN PRINT N'--Consider disabling them with following command:'+CHAR(13)+'exec sp_configure ''show advanced options'', 1;'+CHAR(13)+'RECONFIGURE WITH OVERRIDE;'+CHAR(13)+
	'exec sys.sp_configure N''database mail xps'',0;'+CHAR(13)+'RECONFIGURE;' END
PRINT CHAR(13)+N'--DAC connection is '+CASE WHEN @dac = 1 THEN 'ENABLED' ELSE 'DISABLED' END
IF @dac = 0
	BEGIN PRINT N'--Consider enabling it with following command:'+CHAR(13)+'exec sys.sp_configure N''remote admin connections'',1;'+CHAR(13)+'RECONFIGURE;' END
PRINT CHAR(13)+N'--Remote access connection is '+CASE WHEN @remote = 1 THEN 'ENABLED' ELSE 'DISABLED' END
IF @remote = 0
	BEGIN PRINT N'--Consider disabling it with following command:'+CHAR(13)+'exec sys.sp_configure N''remote access'',0;'+CHAR(13)+'RECONFIGURE;' END
PRINT CHAR(13)+N'--Named pipes protocol is '+CASE WHEN @np_status = 1 THEN 'ENABLED' ELSE 'DISABLED' END
IF @np_status = 1
	BEGIN PRINT N'--Consider disabling Named Pipes protocol, if no application needs it' END
PRINT CHAR(13)+N'--VIA protocol is '+CASE WHEN @via_status = 1 THEN 'ENABLED' ELSE 'DISABLED' END
IF @via_status = 1
	BEGIN PRINT N'--Consider disabling VIA protocol, if no application needs it' END
PRINT CHAR(13)+N'--Static port for this instance is '+@static_port
IF @static_port = '1433' OR @static_port LIKE '%1433,%'
	BEGIN PRINT N'--Default port 1433 is still used, consider changing it' END
PRINT CHAR(13)+N'--SQLBrowser is '+CASE WHEN @v02 = 1 THEN 'ENABLED' ELSE 'DISABLED' END
IF @v02 = 1
	BEGIN PRINT N'--Consider disabling SQLBrowser, if all applications can use static port' END
IF @v11 <> ''
	BEGIN PRINT CHAR(13)+N'--Following databases (except for master, msdb, tempdb) have Guest account enabled: '
	PRINT N'--'+@v11
	PRINT N'--Consider disabling it' END
	ELSE BEGIN PRINT CHAR(13)+N'--None database (except for master, msdb, tempdb) has Guest account enabled' END
IF @v12 <> ''
	BEGIN PRINT CHAR(13)+N'--Following trace flags are set globally for this instance: '
	PRINT N'--'+@v12
	PRINT N'--Consider if following trace flags should be enabled: T1117, T1118, T2371 (all three only up to SQL2014),T3226,T2549,T3042' END
	ELSE BEGIN PRINT CHAR(13)+N'--No trace flags set globally for this instance. Please consider following: T1117, T1118, T2371 (all three only up to SQL2014),T3226,T2549,T3042' END

