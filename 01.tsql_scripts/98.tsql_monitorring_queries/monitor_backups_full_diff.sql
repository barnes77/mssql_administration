;WITH bcks_cte AS (
	SELECT
		sd.[name] AS [database_name]
		,sd.recovery_model_desc AS recovery_model
		,CONVERT(varchar(20), bs.backup_finish_date, 13) AS backup_completed
		,bs.[type]
		,ROW_NUMBER() OVER (PARTITION BY sd.[name],bs.[type] ORDER BY bs.backup_finish_date DESC) AS row_no
	FROM sys.databases AS sd
	LEFT JOIN msdb.dbo.backupset AS bs ON bs.[database_name] = sd.[name]
	WHERE 1=1
		AND sd.database_id <> 2			--exlude tempdb
		AND bs.[type] IN ('D','I') 		--include only diff and full
		AND bs.is_copy_only = 0 		--exlude copy-only
		AND bs.backup_finish_date > DATEADD(DAY, -14, GETDATE())
	), ao_sec_dbs_cte AS (
	SELECT 
		DB_NAME(database_id) AS [database_name]
	FROM sys.dm_hadr_database_replica_states AS dm_hdrs
	LEFT JOIN sys.dm_hadr_availability_replica_states AS dm_ars ON dm_hdrs.replica_id = dm_ars.replica_id
	LEFT JOIN sys.availability_replicas AS sac ON sac.replica_id = dm_hdrs.replica_id
	WHERE 1=1 
		AND sac.replica_server_name = @@SERVERNAME 
		AND LOWER(dm_ars.role_desc) = 'secondary'
	),	final_check AS (
	SELECT 
		sd.[name] AS [database_name]
		,bc01.recovery_model
		,DATEDIFF(HOUR,bc01.backup_completed,GETDATE()) AS hrs_from_full
		,CASE
			WHEN bc01.backup_completed IS NULL THEN 0
			WHEN DATEDIFF(HOUR,bc01.backup_completed,GETDATE()) > 167 THEN 0 --167 hrs instead of 168 hrs not to include the full from week before
			ELSE 1
		END check_full
		,DATEDIFF(HOUR,bc02.backup_completed,GETDATE()) AS hrs_from_diff
		,CASE
			WHEN sd.[name] = 'master' AND DATEDIFF(HOUR,bc01.backup_completed,GETDATE()) < 23 THEN 1
			WHEN sd.[name] = 'master' AND DATEDIFF(HOUR,bc01.backup_completed,GETDATE()) > 23 THEN 0
			WHEN bc02.backup_completed IS NULL THEN 0
			WHEN DATEDIFF(HOUR,bc02.backup_completed,GETDATE()) > 23 THEN 0 --23 hrs instead of 24 hrs not to include the diff from 2 days before
			ELSE 1
		END check_diff
	FROM sys.databases AS sd
	LEFT JOIN bcks_cte AS bc01 ON sd.[name] = bc01.[database_name] AND bc01.[type] = 'D'
	LEFT JOIN bcks_cte AS bc02 ON sd.[name] = bc02.[database_name] AND bc02.[type] = 'I'
	LEFT JOIN ao_sec_dbs_cte AS asdc ON asdc.[database_name] = sd.[name]
	WHERE 1=1
		AND (bc01.row_no = 1 OR bc01.row_no IS NULL) 
		AND (bc02.row_no = 1 OR bc02.row_no IS NULL)
		AND sd.database_id <> 2
		AND asdc.[database_name] IS NULL --exclude databases in secondary replicas
	)
	SELECT 
		[database_name]
	FROM final_check
	WHERE check_full = 0 AND check_diff = 0
