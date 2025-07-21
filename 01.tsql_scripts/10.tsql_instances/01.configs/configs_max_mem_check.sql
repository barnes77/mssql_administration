--Check min and max memory of the instance
SELECT
	[name]
	,value_in_use
	,minimum
	,maximum
FROM sys.configurations
WHERE [name] LIKE '%m%server memory (MB)%'
 
--Change max memory of the istance (if advanced options are shown)
/*
 
exec sys.sp_configure N'max server memory (MB)', N'30000';
GO
RECONFIGURE WITH OVERRIDE;
GO
 
*/
 
--Change max memory of the istance (if advanced options are not shown)
/*
 
exec sys.sp_configure N'show advanced options', N'1';
GO
RECONFIGURE WITH OVERRIDE;
GO
exec sys.sp_configure N'max server memory (MB)', N'30000';
GO
RECONFIGURE WITH OVERRIDE;
GO
exec sys.sp_configure N'show advanced options', N'0';
GO
RECONFIGURE WITH OVERRIDE;
GO
 
*/
