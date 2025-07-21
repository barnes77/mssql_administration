SET NOCOUNT ON;
 
SELECT
	sdb.[name]
	,dbmir.mirroring_state_desc
	,dbmir.mirroring_partner_instance
	,dbmir.mirroring_witness_name
	,dbmir.mirroring_witness_state_desc
FROM sys.database_mirroring AS dbmir
JOIN sys.databases AS sdb ON sdb.database_id = dbmir.database_id
WHERE sdb.database_id > 4;
