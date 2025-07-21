--show current_state of seeding
--source: learn.microsoft.com/en-us/sql/database-engine/availability-groups/windows/distributed-availability-groups?view=sql-server-ver16
SELECT 
	ag.[name] AS ag_name
	,ar.replica_server_name
	,d.[name] AS [database_name]
	,has.current_state
	,has.failure_state_desc AS failure_state
	,has.error_code
	,has.performed_seeding
	,has.start_time
	,has.completion_time
	,has.number_of_attempts
FROM sys.dm_hadr_automatic_seeding AS has
INNER JOIN sys.availability_groups AS ag ON ag.group_id = has.ag_id
INNER JOIN sys.availability_replicas AS ar ON ar.replica_id = has.ag_remote_replica_id
INNER JOIN sys.databases AS d ON d.group_database_id = has.ag_db_id;
