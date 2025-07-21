--Run against DB using CDC
exec sys.sp_cdc_disable_db;
GO
CHECKPOINT;
GO
--Back up and shrink log file
exec sys.sp_cdc_enable_db;
GO
CHECKPOINT;
GO
