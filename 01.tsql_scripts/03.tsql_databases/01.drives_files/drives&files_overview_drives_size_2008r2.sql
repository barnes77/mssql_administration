SET NOCOUNT ON;
 
SELECT DISTINCT
	volume_mount_point AS [name]
	,CAST(total_bytes*1.0/(1024*1024*1024) AS DECIMAL(20,2)) AS total_space
	,CAST(available_bytes*1.0/(1024*1024*1024) AS DECIMAL(20,2)) AS free_space_gb
	,CAST((available_bytes*1.0/(1024*1024*1024))/(total_bytes*1.0/(1024*1024*1024))*100 AS DECIMAL(20,2)) AS [free_space_%]
	,CASE 
		WHEN CAST((available_bytes*1.0/(1024*1024*1024))/(total_bytes*1.0/(1024*1024*1024))*100 AS DECIMAL(20,2)) > 10.01 THEN
			CONCAT('Drive ',volume_mount_point,' has ',CAST(available_bytes*1.0/(1024*1024*1024) AS DECIMAL(20,2)),' GB ('
			,CAST((available_bytes*1.0/(1024*1024*1024))/(total_bytes*1.0/(1024*1024*1024))*100 AS DECIMAL(20,2)),'%) of free space. No action needed.')
		ELSE ''
	END AS ticket_resolution
FROM sys.master_files AS mf
CROSS APPLY sys.dm_os_volume_stats(mf.database_id, mf.file_id)
ORDER BY volume_mount_point ASC;
