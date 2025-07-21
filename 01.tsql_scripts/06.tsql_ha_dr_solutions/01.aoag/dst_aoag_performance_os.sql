--display OS performance counters related to the distributed AOAG named 'distributed_ag'
--source: learn.microsoft.com/en-us/sql/database-engine/availability-groups/windows/distributed-availability-groups?view=sql-server-ver16
SELECT 
	* 
FROM sys.dm_os_performance_counters 
WHERE instance_name LIKE '%distributed_ag%';
