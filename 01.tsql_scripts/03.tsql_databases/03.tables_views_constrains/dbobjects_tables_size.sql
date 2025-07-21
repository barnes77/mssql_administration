/*
Source: stackoverflow.com/questions/7892334/get-size-of-all-tables-in-database
Aim: Get table sizes
*/
SET NOCOUNT ON;
 
SELECT
	DB_NAME() AS [database_name]
	,stab.[name] AS table_name
	,ssch.[name] AS [schema_name]
	,spart.[rows]
	,SUM(au.total_pages) * 8 AS total_space_kb
	,CAST(ROUND(((SUM(au.total_pages) * 8) / 1024.00), 2) AS numeric(36, 2)) AS total_space_mb
	,SUM(au.used_pages) * 8 AS used_space_kb
	,CAST(ROUND(((SUM(au.used_pages) * 8) / 1024.00), 2) AS numeric(36, 2)) AS used_space_mb
	,(SUM(au.total_pages) - SUM(au.used_pages)) * 8 AS unused_space_kb
	,CAST(ROUND(((SUM(au.total_pages) - SUM(au.used_pages)) * 8) / 1024.00, 2) AS numeric(36, 2)) AS unused_space_mb
FROM sys.tables AS stab
INNER JOIN sys.indexes AS sind ON stab.[object_id] = sind.[object_id]
INNER JOIN sys.partitions AS spart ON sind.[object_id] = spart.[object_id] AND sind.index_id = spart.index_id
INNER JOIN sys.allocation_units AS au ON spart.[partition_id] = au.container_id
LEFT OUTER JOIN sys.schemas AS ssch ON stab.[schema_id] = ssch.[schema_id]
WHERE 1=1
	AND stab.[name] LIKE '%%' 
	AND sind.[object_id] > 255 
--	AND stab.is_ms_shipped = 0
GROUP BY stab.[name], ssch.[name], spart.[rows]
ORDER BY total_space_mb DESC, stab.[name];
