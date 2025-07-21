SELECT
	DB_NAME(database_id) AS [database_name]
	,mirroring_witness_name
FROM sys.database_mirroring
WHERE database_id > 4;
 

ALTER DATABASE YourDB SET WITNESS OFF;
ALTER DATABASE YourDB SET WITNESS = 'mirroring_witness_name';
