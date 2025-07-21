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
		AND sd.recovery_model_desc <> 'SIMPLE'		--exlude SIMPLE dbs
		AND sd.is_read_only = 0			--exlude READ_ONLY dbs
		AND bs.[type] = 'L' 		--include only log backups
		AND bs.is_copy_only = 0 		--exlude copy-only
		AND bs.backup_finish_date > DATEADD(DAY, -7, GETDATE())
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
		,bc.recovery_model
		,DATEDIFF(HOUR,bc.backup_completed,GETDATE()) AS hrs_from_log
		,CASE
			WHEN bc.backup_completed IS NULL THEN 0
			WHEN DATEDIFF(HOUR,bc.backup_completed,GETDATE()) > 4 THEN 0 --4 hrs is the threshold
			ELSE 1
		END check_log
	FROM sys.databases AS sd
	LEFT JOIN bcks_cte AS bc ON sd.[name] = bc.[database_name]
	LEFT JOIN ao_sec_dbs_cte AS asdc ON asdc.[database_name] = sd.[name]
	WHERE 1=1
		AND (bc.row_no = 1 OR bc.row_no IS NULL)
		AND sd.database_id <> 2
		AND sd.recovery_model_desc <> 'SIMPLE'
		AND sd.is_read_only = 0			--exlude READ_ONLY dbs
		AND asdc.[database_name] IS NULL --exclude databases in secondary replicas
	)
	SELECT 
		[database_name]
	FROM final_check
	WHERE check_log = 0
