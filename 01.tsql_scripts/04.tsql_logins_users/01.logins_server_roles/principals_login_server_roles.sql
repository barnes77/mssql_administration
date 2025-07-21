/*
Created by Mateusz Wierzbowski
Creation date: 2020/01/07
Aim: check all server roles belonging to a login
*/
SET NOCOUNT ON;
 
SELECT
	spri1.name AS login_name
	,spri1.type_desc AS [login_type]
	,ISNULL(spri2.name,' ') AS server_role
	,spri1.create_date AS created
	,spri1.modify_date AS modified
 
FROM sys.server_principals AS spri1
LEFT JOIN sys.server_role_members AS srm ON spri1.principal_id = srm.member_principal_id
LEFT JOIN sys.server_principals AS spri2 ON spri2.principal_id = srm.role_principal_id
WHERE 1=1 
--	AND spri1.[name] = 'LoginName'
;
