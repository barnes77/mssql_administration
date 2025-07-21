/*
created by: Mateusz Wierzbowski
Creation date: 2020/01/07
Aim: check all database roles belonging to a login
*/
USE tempdb;
SET NOCOUNT ON;
 
IF OBJECT_ID('#permissions_check','U') IS NOT NULL BEGIN DROP TABLE #choose_db_table; END
 
CREATE TABLE #permissions_check (
	[database_name] sysname
	,[user_name] sysname
	,user_type nvarchar(60)
	,db_role sysname NULL
	,created datetime
	,modified datetime
);
 
INSERT INTO #permissions_check exec master.sys.sp_MSforeachdb
'USE [?];
SELECT
	DB_NAME() AS [database_name]
	,dbpri1.name AS [user_name]
	,dbpri1.type_desc AS user_type
	,dbpri2.name AS db_role
	,dbpri1.create_date AS created
	,dbpri1.modify_date AS modified
 
FROM sys.database_principals AS dbpri1
LEFT JOIN sys.database_role_members AS dbrm ON dbpri1.principal_id = dbrm.member_principal_id
LEFT JOIN sys.database_principals AS dbpri2 ON dbpri2.principal_id = dbrm.role_principal_id';
 
SELECT * FROM #permissions_check
WHERE 1=1
	AND [user_name] LIKE '%%' --Provide user's name here
;
 
DROP TABLE #permissions_check;
