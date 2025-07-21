SET NOCOUNT ON;
 
SELECT
	dbpri1.name AS db_user
	,dbpri1.type_desc AS db_user_type
	,ISNULL(dbpri2.name,' ') AS db_role
	,dbpri1.create_date AS created
	,dbpri1.modify_date AS modified
FROM sys.database_principals AS dbpri1
LEFT JOIN sys.database_role_members AS dbrm ON dbpri1.principal_id = dbrm.member_principal_id
LEFT JOIN sys.database_principals AS dbpri2 ON dbpri2.principal_id = dbrm.role_principal_id
WHERE 1=1 
	AND dbpri1.type <> 'R';
