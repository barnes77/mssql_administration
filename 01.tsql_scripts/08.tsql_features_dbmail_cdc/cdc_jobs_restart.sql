--Run against DB using CDC
--stop CDC jobs
exec sys.sp_cdc_stop_job @job_type = N'capture';
GO
exec sys.sp_cdc_stop_job @job_type = N'cleanup';
GO
--start CDC jobs
exec sys.sp_cdc_start_job @job_type = N'capture';
GO
exec sys.sp_cdc_start_job @job_type = N'cleanup';
GO
