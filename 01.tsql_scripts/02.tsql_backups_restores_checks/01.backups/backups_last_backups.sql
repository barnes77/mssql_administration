SET NOCOUNT ON;
 
WITH backup_cte AS (
	SELECT
		[database_name]
		,CASE [type]
			WHEN 'D' THEN 'full'
			WHEN 'L' THEN 'log'
			WHEN 'I' THEN 'diff'
			ELSE 'other'
		END AS backup_type
		,backup_finish_date
		,is_copy_only
		,has_backup_checksums
		,ROW_NUMBER() OVER(PARTITION BY [database_name], [type] ORDER BY backup_finish_date DESC) AS row_no
	FROM msdb.dbo.backupset
	WHERE is_copy_only = 0
)
SELECT
	[database_name]
	,backup_type
	,backup_finish_date
	,is_copy_only
	,has_backup_checksums
FROM backup_cte
WHERE row_no = 1
ORDER BY [database_name];
