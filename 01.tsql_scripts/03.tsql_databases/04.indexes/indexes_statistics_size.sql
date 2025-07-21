/*
Created by: Mateusz Wierzbowski
Creation date: 2020/06/30
Aim: Gather information about indexes
*/
SET NOCOUNT ON;
 
SELECT
	DB_NAME(dm_dius.database_id) AS [database_name]
	,OBJECT_SCHEMA_NAME(dm_dius.[object_id]) AS [schema_name]
	,OBJECT_NAME(dm_dius.[object_id]) AS table_name
	,sind.[name] AS index_name
	,dm_dius.user_seeks
	,dm_dius.user_scans
	,dm_dius.user_lookups
	,dm_dius.user_updates
	,(dm_dius.user_seeks + dm_dius.user_scans + dm_dius.user_lookups + dm_dius.user_updates ) AS user_accesses
	,(dm_dps.used_page_count / 128) AS index_size_mb
FROM sys.dm_db_index_usage_stats AS dm_dius
JOIN sys.indexes AS sind ON dm_dius.index_id = sind.index_id AND dm_dius.[object_id] = sind.[object_id]
JOIN sys.dm_db_partition_stats AS dm_dps ON dm_dius.index_id = dm_dps.index_id AND dm_dius.[object_id] = dm_dps.[object_id]
WHERE 1=1
	AND OBJECTPROPERTY(dm_dius.[object_id],'IsUserTable') = 1 
	AND DB_NAME(dm_dius.database_id) LIKE '%namepattern%' --Condition to filter by database names
	--AND OBJECT_NAME(dm_dius.[object_id]) = 'table_name' --Condition to filter by table names
ORDER BY DB_NAME(dm_dius.database_id),(dm_dius.user_seeks + dm_dius.user_scans + dm_dius.user_lookups + dm_dius.user_updates ) DESC;
