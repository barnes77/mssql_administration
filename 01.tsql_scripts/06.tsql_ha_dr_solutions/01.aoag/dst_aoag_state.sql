--show sync status of distributed AOAG
--source: learn.microsoft.com/en-us/sql/database-engine/availability-groups/windows/distributed-availability-groups?view=sql-server-ver16
SELECT
	ag.[name] AS ag_name
	,ag.is_distributed
	,ar.replica_server_name AS underlying_ag
	,ars.role_desc AS [role]
	,ars.synchronization_health_desc AS sync_status
FROM  sys.availability_groups AS ag
INNER JOIN sys.availability_replicas AS ar ON  ag.group_id = ar.group_id
INNER JOIN sys.dm_hadr_availability_replica_states AS ars ON  ar.replica_id = ars.replica_id
WHERE ag.is_distributed = 1;
