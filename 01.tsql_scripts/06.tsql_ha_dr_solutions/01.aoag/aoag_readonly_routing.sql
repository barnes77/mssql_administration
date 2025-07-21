SET NOCOUNT ON;
 
SELECT 
	ag.name
	,ar01.replica_server_name AS source_replica		
	,ar02.replica_server_name AS readable_replica
	,ar02.read_only_routing_url AS routing_url
	,arorl.routing_priority AS routing_prio
FROM sys.availability_read_only_routing_lists AS arorl
INNER JOIN sys.availability_replicas AS ar01 ON arorl.replica_id = ar01.replica_id
INNER JOIN sys.availability_replicas AS ar02 ON arorl.read_only_replica_id = ar02.replica_id
INNER JOIN sys.availability_groups AS ag ON ag.group_id = ar01.group_id
ORDER BY source_replica,routing_prio;
