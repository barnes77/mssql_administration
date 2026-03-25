/*
Created by: Mateusz Wierzbowski
Creation date: 2019/10/30
Aim: List all permissions on database level of particular principle (role/login)
*/
SET NOCOUNT ON;
--USE [YourDB]
 
SELECT
	OBJECT_NAME(dbper.major_id) AS [object_name]
	,dbper.[permission_name]
	,dbper.state_desc
	,dbpri1.[name] AS granted_by
	,dbpri2.[name] AS granted_to
FROM sys.database_permissions AS dbper
JOIN sys.database_principals AS dbpri1 ON dbper.grantor_principal_id = dbpri1.principal_id
JOIN sys.database_principals AS dbpri2 ON dbper.grantee_principal_id = dbpri2.principal_id
WHERE 1=1
	AND OBJECT_NAME(dbper.major_id) IS NOT NULL
	AND dbpri.[name] LIKE '%principalname%' --Comment out this condition to list all permissions on database level
ORDER BY OBJECT_NAME(dbper.major_id) ASC;
