--show endpoint url and sync state for AOAG and distributed AOAG
--source: learn.microsoft.com/en-us/sql/database-engine/availability-groups/windows/distributed-availability-groups?view=sql-server-ver16
SELECT
	ag.[name] AS ag_name
	,ag.is_distributed
	,ar.replica_server_name AS replica_name
	,ar.endpoint_url
	,ar.availability_mode_desc
	,ar.failover_mode_desc
	,ar.primary_role_allow_connections_desc AS allow_connections_primary
	,ar.secondary_role_allow_connections_desc AS allow_connections_secondary
	,ar.seeding_mode_desc AS seeding_mode
FROM sys.availability_replicas AS ar
JOIN sys.availability_groups AS ag ON ar.group_id = ag.group_id;
