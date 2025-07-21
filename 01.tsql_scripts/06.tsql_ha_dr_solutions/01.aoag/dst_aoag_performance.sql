--show underlying performance of distributed AOAG
--source: learn.microsoft.com/en-us/sql/database-engine/availability-groups/windows/distributed-availability-groups?view=sql-server-ver16
SELECT
	ag.[name] AS distributed_ag_name
	,ar.replica_server_name AS underlying_ag
	,dbs.[name] AS [database]
	,ars.role_desc AS [role]
	,drs.synchronization_health_desc AS sync_status
	,drs.log_send_queue_size
	,drs.log_send_rate
	,drs.redo_queue_size
	,.redo_rate
FROM sys.databases AS dbs
INNER JOIN sys.dm_hadr_database_replica_states AS drs ON dbs.database_id = drs.database_id
INNER JOIN sys.availability_groups AS ag ON drs.group_id = ag.group_id
INNER JOIN sys.dm_hadr_availability_replica_states AS ars ON ars.replica_id = drs.replica_id
INNER JOIN sys.availability_replicas AS ar ON ar.replica_id = ars.replica_id
WHERE ag.is_distributed = 1;
