SET NOCOUNT ON;
 
SELECT 
	sd.name AS 'db_name'
	,sc.name AS 'cert_name'
	,dm_dek.encryptor_type
	,CASE
		WHEN dm_dek.encryption_state = 3 THEN 'encrypted'
		WHEN dm_dek.encryption_state = 2 THEN 'in_progress'
		ELSE 'unencrypted'
	END AS [encrytion_state]
	,dm_dek.encryption_state
	,dm_dek.percent_complete
	,dm_dek.key_algorithm
	,dm_dek.key_length
	--,dm_dek.* 
FROM sys.databases AS sd
LEFT JOIN sys.dm_database_encryption_keys AS dm_dek ON sd.database_id = dm_dek.database_id
LEFT JOIN sys.certificates AS sc ON dm_dek.encryptor_thumbprint = sc.thumbprint
WHERE dm_dek.encryptor_type IS NOT NULL;
