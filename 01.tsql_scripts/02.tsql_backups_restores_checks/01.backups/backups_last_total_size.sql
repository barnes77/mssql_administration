/*
Created by: Mateusz Wierzbowski
Creation date: 2024/07/14
Aim: Get size of last backup of all databases during last execution
*/
SET NOCOUNT ON;
 
;WITH backup_cte AS (
SELECT
    [database_name]
    ,recovery_model
    ,CASE
        WHEN [type] = 'L' THEN 'log'
        WHEN [type] = 'D' THEN 'full'
        ELSE 'diff'
    END backup_type
    ,CASE
        WHEN [type] = 'L' THEN 3
        WHEN [type] = 'D' THEN 1
        ELSE 2
    END backup_type_order
    ,CAST((compressed_backup_size / (1024*1024)) AS DECIMAL(10,2)) AS size_mb
    ,ROW_NUMBER() OVER ( PARTITION BY [database_name], [type] ORDER BY backup_finish_date DESC ) AS row_no
FROM msdb.dbo.backupset
WHERE backup_finish_date > GETDATE()-14 AND is_copy_only = 0
), backup_cte2 AS (
SELECT
    sdb.[name] AS [database_name]
    ,bc1.backup_type AS backup_type
    ,bc1.size_mb
    ,bc1.backup_type_order
FROM sys.databases AS sdb
LEFT JOIN backup_cte AS bc1 ON sdb.[name] = bc1.[database_name]
WHERE bc1.row_no = 1 AND sdb.database_id <> 2
)
SELECT 
    backup_type
    ,SUM(size_mb) AS total_backup_size_mb
    ,CAST(SUM(size_mb)/1024 AS decimal(10,2)) AS total_backup_size_gb
FROM backup_cte2
GROUP BY backup_type, backup_type_order
ORDER BY backup_type_order;

