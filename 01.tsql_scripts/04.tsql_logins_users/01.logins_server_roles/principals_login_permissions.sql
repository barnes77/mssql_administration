SET NOCOUNT ON;
 
SELECT
	srvpri1.[name] AS login_name
	,srvpri1.type_desc AS [login_type]
	,srvpri2.[name] AS granted_by
	,srvper.[permission_name]
	,srvper.[state_desc]
	,sobj.[name] AS [object_name]
	,sobj.[type_desc] AS object_type
FROM sys.server_permissions AS srvper
LEFT JOIN sys.objects AS sobj ON srvper.major_id = sobj.object_id
LEFT JOIN sys.server_principals AS srvpri1 ON srvper.grantee_principal_id = srvpri1.principal_id
LEFT JOIN sys.server_principals AS srvpri2 ON srvper.grantor_principal_id = srvpri2.principal_id
WHERE 1=1 
	--AND srvpri1.[name] = 'UserName';
	--AND srvper.[permission_name] = 'VIEW SERVER STATE';
	--AND sobj.[name] = 'Hadr_endpoint';
