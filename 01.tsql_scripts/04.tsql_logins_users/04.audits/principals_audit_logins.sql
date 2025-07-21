/*
Created by: Mateusz Wierzbowski
Creation date: 2019/01/24
*/
SET NOCOUNT ON;
 
;WITH audit_logins_cte AS (	
	SELECT
		spri.[name] AS login_name
		,spri.type_desc AS [login_type]
		,CONVERT(CHAR(16),spri.create_date,20) AS created_on
		,CASE
			WHEN spri.is_disabled = 1 THEN 'disabled'
			ELSE 'enabled'
		END AS login_status
		,srm.member_principal_id
		,srm.role_principal_id
		,spri.[sid]
		FROM sys.server_principals AS spri
		LEFT JOIN sys.server_role_members AS srm ON spri.principal_id = srm.member_principal_id
		WHERE spri.type IN ('S','U','G','K')
)
SELECT
	alc.login_name
	,alc.[login_type]
	,alc.created_on
	,alc.login_status
	,ISNULL(spri.[name],'no_server_role') AS server_role
FROM audit_logins_cte AS alc
LEFT JOIN sys.server_principals AS spri ON alc.role_principal_id = spri.principal_id
-- WHERE spri.[name] = 'sysadmin'
ORDER BY alc.login_name;
