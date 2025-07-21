SET NOCOUNT ON;
 
SELECT
	dm_hnim.ag_name
	,DB_NAME(dm_hdrs.database_id) AS [db_name]
	,dm_hdrs.synchronization_state_desc
	,dm_hdrs.synchronization_health_desc
	,dm_hdrs.is_primary_replica
FROM sys.dm_hadr_database_replica_states AS dm_hdrs
LEFT JOIN sys.dm_hadr_name_id_map AS dm_hnim ON dm_hdrs.group_id = dm_hnim.ag_id
LEFT JOIN sys.availability_replicas AS ar ON dm_hdrs.replica_id = ar.replica_id 
WHERE ar.replica_server_name = @@SERVERNAME; --choose to show state only on current replica
--WHERE ar.replica_server_name <> @@SERVERNAME; --choose to show state only on other replicas

