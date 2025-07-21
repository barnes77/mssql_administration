USE tempdb
DECLARE 
	@ssas nvarchar (100),@ssrs nvarchar (100),@ssis nvarchar (100)
	,@reg_path_ssas nvarchar (250),@reg_path_ssrs nvarchar (250),@reg_path_ssis nvarchar (250)
	,@version int = CAST(SUBSTRING(CONVERT(varchar(40),SERVERPROPERTY('ProductVersion')),1,CHARINDEX('.',CONVERT(varchar(40),SERVERPROPERTY('ProductVersion')))-1) AS int)
 
IF @@SERVICENAME <> 'MSSQLServer'
	BEGIN
		SET @reg_path_ssas = 'SYSTEM\ControlSet001\Services\MSOLAP$'+ @@SERVICENAME;
		SET @reg_path_ssrs = 'SYSTEM\ControlSet001\Services\ReportServer$'+ @@SERVICENAME;
	END
	ELSE
		BEGIN
			SET @reg_path_ssas = 'SYSTEM\ControlSet001\Services\MSSQLServerOLAPService';
			SET @reg_path_ssrs = 'SYSTEM\ControlSet001\Services\ReportServer';
		END;
 
IF @version = 9
	BEGIN SET @reg_path_ssis = 'SYSTEM\ControlSet001\Services\MsDtsServer'; END
ELSE IF @version = 10 
	BEGIN SET @reg_path_ssis = 'SYSTEM\ControlSet001\Services\MsDtsServer100'; END
ELSE IF @version = 11
	BEGIN SET @reg_path_ssis = 'SYSTEM\ControlSet001\Services\MsDtsServer110'; END
ELSE IF @version = 12
	BEGIN SET @reg_path_ssis = 'SYSTEM\ControlSet001\Services\MsDtsServer120'; END
ELSE IF @version = 13
	BEGIN SET @reg_path_ssis = 'SYSTEM\ControlSet001\Services\MsDtsServer130'; END
ELSE IF @version = 14
	BEGIN SET @reg_path_ssis = 'SYSTEM\ControlSet001\Services\MsDtsServer140'; END
ELSE IF @version = 15
	BEGIN SET @reg_path_ssis = 'SYSTEM\ControlSet001\Services\MsDtsServer150'; END
 
exec [master].dbo.xp_regread N'HKEY_LOCAL_MACHINE', @reg_path_ssas, N'ObjectName', @ssas output, 'no_output';
exec [master].dbo.xp_regread N'HKEY_LOCAL_MACHINE', @reg_path_ssrs, N'ObjectName', @ssrs output, 'no_output';
exec [master].dbo.xp_regread N'HKEY_LOCAL_MACHINE', @reg_path_ssis, N'ObjectName', @ssis output, 'no_output';
 
SELECT
	CASE WHEN @ssas IS NOT NULL THEN 1 ELSE 0 END AS SSAS
	,CASE WHEN @ssrs IS NOT NULL THEN 1 ELSE 0 END AS SSRS
	,CASE WHEN @ssis IS NOT NULL THEN 1 ELSE 0 END AS SSIS
