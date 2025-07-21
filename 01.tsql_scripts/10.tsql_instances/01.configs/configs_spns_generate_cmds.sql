/*
Created by: Mateusz Wierzbowski
Creation date: 2022/06/16-20
Aim: Generate a complete list of SPNs for current instance
*/
 
USE tempdb;
SET NOCOUNT ON;
 
/*Step01a: Declare domain name*/
DECLARE @domain nvarchar(200) = 'SQLLAB.local'; --Domain name here, needed to calculate SPNs 
 
/*Step01b: Declare other variables, clean up old tables and create new ones*/
DECLARE @stat_port nvarchar(10), @dyn_port nvarchar(10);
DECLARE @instance nvarchar(128);
DECLARE @archive int;
DECLARE @svc_acc nvarchar(128);
 
IF OBJECT_ID('#dba_spns','U') IS NOT NULL DROP TABLE #dba_spns;
IF OBJECT_ID('#dba_enum_error_logs','U') IS NOT NULL DROP TABLE #dba_enum_error_logs;
IF OBJECT_ID('#dba_read_error_log','U') IS NOT NULL DROP TABLE #dba_read_error_log;
 
CREATE TABLE #dba_spns (
	command nvarchar(2000)
	,port_no int NULL
);
CREATE TABLE #dba_enum_error_logs (	
	[archive] int,
	[date] datetime,
	log_file_size_byte int
);
CREATE TABLE #dba_read_error_log (	
	log_date datetime,
	process_info varchar(50),
	[text] varchar(4000)
);
 
/*Step02: Populate variables*/
exec [master].dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\Microsoft SQL Server\MSSQLServer\SuperSocketNetLib\Tcp\IpAll', N'TcpDynamicPorts', @dyn_port output, 'no_output';
exec [master].dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\Microsoft SQL Server\MSSQLServer\SuperSocketNetLib\Tcp\IpAll', N'TcpPort', @stat_port output, 'no_output';
 
SELECT @instance = CAST(SERVERPROPERTY('InstanceName') AS nvarchar(128));
SELECT @svc_acc = RIGHT(service_account,LEN(service_account)-CHARINDEX('\',service_account)) FROM sys.dm_server_services WHERE servicename LIKE 'SQL Server (%';
 
/*Step03: Calculate SPNs based on the domain and instance name, both for an instance and for the static port*/
IF @instance IS NOT NULL AND @instance <> 'MSSQLSERVER'
BEGIN
	INSERT INTO #dba_spns (command,port_no)
	SELECT 
		CONCAT('setspn -s MSSQLSvc/',CAST(SERVERPROPERTY('MachineName') AS nvarchar(128)),'.',@domain,':',@instance,' ',@svc_acc)
		,NULL AS port_no;
	
END
ELSE IF @instance IS NOT NULL AND @instance <> 'MSSQLSERVER'
BEGIN
	INSERT INTO #dba_spns (command,port_no)
	SELECT 
		CONCAT('setspn -s MSSQLSvc/',CAST(SERVERPROPERTY('MachineName') AS nvarchar(128)),'.',@domain,' ',@svc_acc)
		,NULL AS port_no;
END
 
IF @stat_port IS NOT NULL
BEGIN
	INSERT INTO #dba_spns (command,port_no)
	SELECT 
		CONCAT('setspn -s MSSQLSvc/',CAST(SERVERPROPERTY('MachineName') AS nvarchar(128)),'.',@domain,':',@stat_port,' ',@svc_acc)
		,@stat_port AS port_no;
END
 
/*Step04: Find SPNs that SQL Server attempted to registered, but failed to do so*/
INSERT INTO #dba_enum_error_logs
	exec [sys].[xp_enumerrorlogs];
 
DECLARE cur_enumerrorlogs CURSOR FOR SELECT [archive] FROM #dba_enum_error_logs ORDER BY [archive] DESC;
OPEN cur_enumerrorlogs;
FETCH NEXT FROM cur_enumerrorlogs INTO @archive;
 
WHILE @@FETCH_STATUS = 0
BEGIN
	INSERT INTO #dba_read_error_log exec sys.xp_readerrorlog @archive;
	FETCH NEXT FROM cur_enumerrorlogs INTO @archive;
END
 
CLOSE cur_enumerrorlogs;
DEALLOCATE cur_enumerrorlogs;
 
/*Step04a: Remove SPNs using instance names instead of port via regex and retrieve port number*/
INSERT INTO #dba_spns (command,port_no)
SELECT 
	CONCAT('setspn -s ',
		RIGHT(LEFT([text],CHARINDEX(' ]',[text])),LEN(LEFT([text],CHARINDEX(' ]',[text])))-CHARINDEX('[ ',LEFT([text],CHARINDEX(' ]',[text])))),
		@svc_acc) AS command
	,SUBSTRING([text],CHARINDEX(':',[text],CHARINDEX('[',[text]))+1,CHARINDEX(']',[text])-CHARINDEX(':',[text],CHARINDEX('[',[text]))-2) AS port_no
FROM #dba_read_error_log
WHERE LOWER([text]) LIKE '%could not register the service principal name (spn)%'
	AND LEFT(SUBSTRING([text],CHARINDEX(':',[text],CHARINDEX('[',[text]))+1,CHARINDEX(']',[text])-CHARINDEX(':',[text],CHARINDEX('[',[text]))-2),1) NOT LIKE '[A-Za-z]';
 
/*Step04b: Remove duplicate SPNs */
;WITH duplicates_cte AS (
	SELECT 
		command,port_no
		,ROW_NUMBER() OVER (PARTITION BY command,port_no ORDER BY command) AS row_no
	FROM #dba_spns
)
DELETE FROM duplicates_cte
WHERE row_no > 1;
 
/*Step05: Retrieve cleaned up list of SPNs rulling out SPNs attempted for dynamic ports based on the current dynamic port or the dynamic ports range */
SELECT 
	command
FROM #dba_spns
WHERE port_no IS NULL OR (port_no <> ISNULL(@dyn_port,0) AND port_no NOT BETWEEN 49152 AND 65535);
 
DROP TABLE #dba_spns
