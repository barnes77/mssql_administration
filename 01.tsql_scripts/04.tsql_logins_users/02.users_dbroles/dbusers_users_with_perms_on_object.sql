SET NOCOUNT ON;
 
SELECT
	dbpri.principal_id
	,dbpri.[name]
	,dbpri.[type_desc]
	,dbpri.authentication_type_desc
	,dbper.state_desc
	,dbper.[permission_name]
	,ssch.[name] + '.' + sobj.[name] AS permission_object
FROM sys.database_principals AS dbpri
JOIN sys.database_permissions AS dbper ON dbper.grantee_principal_id = dbpri.principal_id
JOIN sys.objects AS sobj ON dbper.major_id = sobj.[object_id]
JOIN sys.schemas AS ssch ON sobj.[schema_id] = ssch.[schema_id]
WHERE 1=1
--	AND ssch.[name] = 'schema'
--	AND sobj.[name] = 'object'
;
