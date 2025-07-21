--USE YourDB
SET NOCOUNT ON;
 
SELECT
	dbpri2.name AS db_user
	,dbpri1.name AS db_role
	,dbpri2.create_date
	,dbpri2.modify_date
	,dbpri2.[sid]
FROM sys.database_principals AS dbpri1
LEFT JOIN sys.database_role_members AS dbrm ON dbpri1.principal_id = dbrm.role_principal_id
RIGHT JOIN sys.database_principals AS dbpri2 ON dbpri2.principal_id = dbrm.member_principal_id
WHERE 1=1
	AND dbpri2.[type] <> 'R' 
	AND dbpri2.[type] <> 'A';
