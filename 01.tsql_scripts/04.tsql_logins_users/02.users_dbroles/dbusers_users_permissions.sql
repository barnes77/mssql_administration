/*
Source: dba.stackexchange.com/questions/36618/list-all-permissions-for-a-given-role
Aim: Show permissions for particular principal
*/
SET NOCOUNT ON;
 
SELECT
	DB_NAME() AS [database_name]
	,dbpri1.[name] AS login_name
	,dbpri1.type_desc AS [login_type]
	,dbpri2.[name] AS granted_by
	,dbper.[permission_name]
	,dbper.[state_desc]
	,sobj.[name] AS [object_name]
	,sobj.[type_desc] AS object_type
FROM sys.database_permissions AS dbper
LEFT JOIN sys.objects AS sobj ON dbper.major_id = sobj.object_id
LEFT JOIN sys.database_principals AS dbpri1 ON dbper.grantee_principal_id = dbpri1.principal_id
LEFT JOIN sys.database_principals AS dbpri2 ON dbper.grantor_principal_id = dbpri2.principal_id
WHERE 1=1 
	AND dbpri1.[name] = 'UserName';
