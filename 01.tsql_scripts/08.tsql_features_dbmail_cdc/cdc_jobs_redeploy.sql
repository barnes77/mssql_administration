exec sys.sp_cdc_add_job @job_type = N'capture'; -- adds capture job 
exec sys.sp_cdc_add_job @job_type = N'cleanup', @start_job = 0, @retention = 5760; --adds cleanup job with retention expressed in minutes
