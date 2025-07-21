SET NOCOUNT ON;
 
SELECT
	ssrv.server_id AS linked_server_id
	,ssrv.[name] AS linked_server
	,ssrv.product AS type_of_linked_server
	,ssrv.[provider] AS provider_for_linked_server
	,ssrv.modify_date AS linked_server_config_modification
	,ll.uses_self_credential AS use_self_creds
	,spri.[name] AS local_user
	,ll.remote_name AS remote_user
	,ll.modify_date AS remote_user_modification
FROM sys.servers AS ssrv
LEFT JOIN sys.linked_logins AS ll ON ll.server_id = ssrv.server_id
LEFT JOIN sys.server_principals AS spri ON spri.principal_id = ll.local_principal_id
WHERE 1=1
	AND ssrv.is_linked = 1
--	AND ssrv.name LIKE '%052%'
;
