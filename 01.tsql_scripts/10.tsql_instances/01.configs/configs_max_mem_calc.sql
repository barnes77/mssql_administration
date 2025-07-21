/*
Created by: Mateusz Wierzbowski
Creation date: 2021/04/23
Aim: Automate calculation of Max Memory setting and creation of commands to change them
*/
SET NOCOUNT ON;
 
DECLARE @current_mb int, @ram_mb decimal(10,2), @ram_gb decimal(10,2)
	,@ram_simple_gb decimal(10,0),@ram_simple_mb decimal(10,0),@ram_detailed_gb decimal(10,0), @ram_detailed_mb decimal(10,0);
 
--get value of available RAM on the server
SELECT @ram_mb = total_physical_memory_kb/1024 FROM sys.dm_os_sys_memory
SELECT @ram_gb = total_physical_memory_kb/(1024*1024) FROM sys.dm_os_sys_memory
--simple estimation -- calculation: 85% * server memory - memory for applications, IF it's not a dedicated server for SQL
SET @ram_simple_gb = @ram_gb * 0.85
SET @ram_simple_mb = @ram_simple_gb * 1024
--detailed estimation -- calculation: server memory - 2GB - 1GB for each 4GB of RAM up to 16GB of RAM - 1GB for every 8GB over 16GB of RAM
IF @ram_gb <= 16
	BEGIN SET @ram_detailed_gb = @ram_gb - 2 - (@ram_gb/4) END
ELSE
	BEGIN SET @ram_detailed_gb = @ram_gb - 2 - 4 - ((@ram_gb-16)/16) END
SET @ram_detailed_mb = @ram_detailed_gb * 1024
 
--summary
SELECT
	[value] AS curr_sql_max_mem_mb
	,CAST((CAST([value] AS decimal(20,2))/@ram_mb)*100.0 AS decimal(10,2)) AS perc_of_os_ram
	,@ram_gb AS os_ram_gb
	,@ram_simple_mb AS opt_sql_max_mem_mb_simple
	,CAST((@ram_simple_mb/@ram_mb)*100.0 AS decimal(10,2)) AS perc_of_os_ram_simple
	,@ram_detailed_mb AS opt_sql_max_mem_mb_detailed
	,CAST((@ram_detailed_mb)/@ram_mb*100.0 AS decimal(10,2)) AS perc_of_os_ram_detailed
FROM sys.configurations
WHERE [name] = 'max server memory (MB)'
 

IF ((SELECT [value] FROM sys.configurations WHERE [name] = 'show advanced options') = 0)
BEGIN
	SELECT 'exec sys.sp_configure N''show advanced options'', N''1'' RECONFIGURE WITH OVERRIDE;'
		+' exec sys.sp_configure N''max server memory (MB)'', N'''+CAST(CAST(@ram_simple_mb AS int) AS nvarchar(30))+''' RECONFIGURE WITH OVERRIDE;'
		+' exec sys.sp_configure N''show advanced options'', N''0'' RECONFIGURE WITH OVERRIDE;' AS [script_simple]
	,'exec sys.sp_configure N''show advanced options'', N''1'' RECONFIGURE WITH OVERRIDE;'
		+' exec sys.sp_configure N''max server memory (MB)'', N'''+CAST(CAST(@ram_detailed_mb AS int) AS nvarchar(30))+''' RECONFIGURE WITH OVERRIDE;'
		+' exec sys.sp_configure N''show advanced options'', N''0'' RECONFIGURE WITH OVERRIDE;' AS [script_detailed]
END
ELSE
BEGIN
	SELECT 'exec sys.sp_configure N''max server memory (MB)'', N'''+CAST(CAST(@ram_simple_mb AS int) AS nvarchar(30))+''' RECONFIGURE WITH OVERRIDE;' AS [script_simple]
	,'exec sys.sp_configure N''max server memory (MB)'', N'''+CAST(CAST(@ram_detailed_mb AS int) AS nvarchar(30))+''' RECONFIGURE WITH OVERRIDE;' AS [script_detailed]
END
