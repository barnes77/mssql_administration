
SET NOCOUNT ON;
 
SELECT
	CASE
		WHEN num_of_reads = 0 THEN 0
		ELSE (io_stall_read_ms / num_of_reads)
	END AS read_latency
	,CASE
		WHEN num_of_writes = 0 THEN 0
		ELSE (io_stall_write_ms / num_of_writes)
	END AS write_latency
	,CASE
		WHEN (num_of_reads = 0 AND num_of_writes = 0) THEN 0
		ELSE (io_stall / (num_of_reads + num_of_writes))
	END AS latency
	,CASE
		WHEN num_of_reads = 0 THEN 0
		ELSE (num_of_bytes_read / num_of_reads)
	END AS avg_bytes_per_read
	,CASE
		WHEN num_of_writes = 0 THEN 0
		ELSE (num_of_bytes_written / num_of_writes)
	END avg_bytes_per_write
	,CASE
		WHEN (num_of_reads = 0 AND num_of_writes = 0) THEN 0
		ELSE ((num_of_bytes_read + num_of_bytes_written) / (num_of_reads + num_of_writes))
	END AS avgbpertransfer
	,LEFT (mf.physical_name, 2) AS drive
	,DB_NAME (dm_ivfs.database_id) AS [database_name]
	,mf.physical_name
FROM sys.dm_io_virtual_file_stats (NULL,NULL) AS dm_ivfs
JOIN sys.master_files AS mf ON dm_ivfs.database_id = mf.database_id AND dm_ivfs.[file_id] = mf.[file_id]
--ORDER BY lower(physical_name)
ORDER BY latency DESC;
