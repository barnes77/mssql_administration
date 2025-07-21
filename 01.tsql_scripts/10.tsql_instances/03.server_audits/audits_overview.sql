/*
Created by: Mateusz Wierzbowski
Creation date: 2022/07/04
Aim: Get an overview of existing server audits
*/
SELECT 
	sa.[name] AS audit_name
	,sa.create_date
	,sa.modify_date
	,SUSER_NAME(sa.principal_id) AS audit_owner
	,CONCAT(sfa.log_file_path,sfa.log_file_name) AS log_file
	,sfa.max_file_size AS log_file_max_size_mb
	,sfa.max_files
	,sfa.max_rollover_files
	,sfa.reserve_disk_space
	,sfa.retention_days
FROM sys.server_audits AS sa
LEFT JOIN sys.server_file_audits AS sfa ON sfa.audit_id = sa.audit_id
ORDER BY sa.[name];
