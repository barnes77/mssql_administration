/*
Created by: Mateusz Wierzbowski
Creation date: 2022/07/04
Aim: Get an overview of all defined server audits' actions 
*/
SELECT 
	sa.[name] AS audit_name
	,sa.create_date
	,sa.modify_date
	,SUSER_NAME(sa.principal_id) AS audit_owner
	,sa.predicate
	,sasd.audit_action_name
	,sasd.audit_action_id
	,sasd.class_desc
	,sasd.audited_result
	,sasd.is_group
FROM sys.server_audits AS sa
LEFT JOIN sys.server_audit_specifications AS sas ON sas.server_specification_id = sa.audit_id
LEFT JOIN sys.server_audit_specification_details AS sasd ON sasd.server_specification_id = sas.server_specification_id
ORDER BY sa.[name],sasd.audit_action_name;
