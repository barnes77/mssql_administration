--get info about replicas' configs
SET NOCOUNT ON;
 
SELECT
	ar.replica_server_name
	,dm_hnim.ag_name
	,ar.failover_mode_desc
	,ar.availability_mode_desc
	,ar.primary_role_allow_connections_desc
	,ar.secondary_role_allow_connections_desc
	,ar.[endpoint_url]
FROM sys.availability_replicas AS ar
LEFT JOIN sys.dm_hadr_name_id_map AS dm_hnim ON ar.group_id = dm_hnim.ag_id
ORDER BY dm_hnim.ag_name,ar.replica_server_name;
