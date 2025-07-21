/*
Created by: Mateusz Wierzbowski
Creation date: 2022/07/04
Aim: Read server audit logs
*/
--Step01: Get information about server audits' log files on the instance
SELECT 
	sa.[name] AS audit_name
	,CONCAT(sfa.log_file_path,sa.[name],'*') AS log_file
FROM sys.server_audits AS sa
LEFT JOIN sys.server_file_audits AS sfa ON sfa.audit_id = sa.audit_id

--Step02: Replace filepath_to_audit_file with correct log file
SELECT TOP 10
	fgaf.event_time
	,fgaf.[session_id]
	--,fgaf.application_name --For SQL2017+
	--,fgaf.client_ip --For SQL2017+
	,dac.name AS action_name
	,dac.class_desc AS action_class
	,fgaf.succeeded
	,fgaf.[database_name]
	,fgaf.server_principal_name
	,fgaf.database_principal_name
	,fgaf.[object_name]
	,CASE
		WHEN fgaf.target_database_principal_name = 0 THEN NULL
		ELSE fgaf.target_database_principal_name
	END AS target_database_principal_name
	,CASE
		WHEN fgaf.target_server_principal_name = 0 THEN NULL
		ELSE fgaf.target_server_principal_name
	END AS target_server_principal_name
	,fgaf.[statement]
FROM sys.fn_get_audit_file ('filepath_to_audit_file',default,default) AS fgaf
LEFT JOIN sys.dm_audit_class_type_map AS dactp ON dactp.class_type = fgaf.class_type
LEFT JOIN sys.dm_audit_actions AS dac ON dac.action_id = fgaf.action_id AND dac.class_desc = dactp.class_type_desc
WHERE 1=1
	AND fgaf.[object_name] <> 'telemetry_xevents' AND fgaf.server_principal_name NOT LIKE '%TELEMETRY%'
--	AND fgaf.[statement] LIKE '%%'
--	AND fgaf.server_principal_name LIKE '%%'
--	AND fgaf.server_principal_name NOT LIKE '%%'
--	AND fgaf.[database_name] LIKE '%%'
--	AND fgaf.[database_name] NOT LIKE '%%'
--	AND fgaf.target_server_principal_name LIKE '%%'
--	AND fgaf.[object_name] LIKE '%%'
ORDER BY fgaf.event_time DESC;
