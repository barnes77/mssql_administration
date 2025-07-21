USE tempdb;
SET NOCOUNT ON;
 
IF OBJECT_ID('#dbcc_results','U') IS NOT NULL BEGIN DROP TABLE #dbcc_results; END
 
CREATE TABLE #dba_file_info_xp (
	[line] varchar(2000)
);
 
/* First part of wrapper */
DECLARE @v_cmdshell sql_variant, @v_advanced_options sql_variant
SELECT @v_advanced_options = [value] FROM sys.configurations WHERE LOWER([name]) = 'show advanced options'
SELECT @v_cmdshell = [value] FROM sys.configurations WHERE LOWER([name]) = 'xp_cmdshell'
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
 

INSERT INTO #dba_file_info_xp
	exec xp_cmdshell 'wmic /node:"%COMPUTERNAME%" Volume Where DriveType="3" Get Capacity,FreeSpace,Name'
 
SELECT
	LEFT(RIGHT([line],LEN([line])-CHARINDEX(':',[line])+2),CHARINDEX(' ',RIGHT([line],LEN([line])-CHARINDEX(':',[line])+2))-1) AS [name]
	,CAST((CAST(LEFT([line],CHARINDEX(' ',[line])-1) AS decimal(20,2))*1.0/(1024*1024*1024)) AS decimal(20,2)) AS total_space
	,CAST((CAST(LTRIM(RTRIM(LEFT(LTRIM(RIGHT([line],LEN([line])-CHARINDEX(' ',[line])-1)),CHARINDEX(' ',LTRIM(RIGHT([line],LEN([line])-CHARINDEX(' ',[line])-1)))))) AS decimal(20,2))*1.0/(1024*1024*1024)) AS decimal(20,2)) AS free_space_gb
	,CAST(100*CAST((CAST(LTRIM(RTRIM(LEFT(LTRIM(RIGHT([line],LEN([line])-CHARINDEX(' ',[line])-1)),CHARINDEX(' ',LTRIM(RIGHT([line],LEN([line])-CHARINDEX(' ',[line])-1)))))) AS decimal(20,2))*1.0/(1024*1024*1024)) AS decimal(20,2))
		/CAST((CAST(LEFT([line],CHARINDEX(' ',[line])-1) AS decimal(20,2))*1.0/(1024*1024*1024)) AS decimal(20,2)) AS decimal(20,2)) AS [free_space_%]
FROM #dba_file_info_xp WHERE [line] LIKE '%:%'
ORDER BY [name] ASC;
DROP TABLE #dba_file_info_xp;
 
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
