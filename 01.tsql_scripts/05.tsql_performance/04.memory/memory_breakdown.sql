
SET NOCOUNT ON;
 
SELECT
	(pages_kb + awe_allocated_kb + virtual_memory_committed_kb)/1024 AS memory_mb
	, *
FROM sys.dm_os_memory_clerks
ORDER BY memory_mb DESC;
--SQL allocations counted into buffer pool limit (like CLR, memory for execution plans, sort&hash, etc.) will STEAL the memory from the buffer pool
