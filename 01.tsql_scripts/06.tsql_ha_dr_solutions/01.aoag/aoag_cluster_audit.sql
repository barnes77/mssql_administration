/*
Created by: Mateusz Wierzbowski
Creation date (v0.8): 2019/01/24
Creation date (v1.0): 2019/07/23
Creation date (v1.2): 2021/04/19
Creation date (v1.2): 2021/04/20
Aim: Check location of DB files in and outside of AGGroups, their size and relative consumption of drive space
Compatibility: SQL 2012+
*/
SET NOCOUNT ON;
 
WITH drives_cte AS (
	SELECT
		sdb.[name] AS [database_name]
		,CASE
			WHEN CAST(sdb.replica_id AS CHAR(36)) IS NULL THEN 'local_db'
			ELSE 'AlwaysOn DB'
			END AS ag_or_local
		,ISNULL(ag.[name],'local_dbs') AS ag_name
		,volume_mount_point AS drive
		,CAST(mf.size*8.0/(1024*1024) AS decimal(10,2)) AS db_files_size_gb
		,CAST((total_bytes*1.00/(1024*1024*1024)) AS decimal(10,2)) AS drive_size_gb
		,CAST((available_bytes*1.00/(1024*1024*1024)) AS decimal(10,2)) AS drive_free_space_gb
		,CAST((available_bytes*1.00/(1024*1024*1024))*100/(total_bytes*1.00/(1024*1024*1024)) AS decimal(10,2)) AS drive_free_space_perc
		,mf.physical_name AS db_file
	FROM sys.databases AS sdb
	JOIN sys.master_files AS mf ON sdb.database_id = mf.database_id
	CROSS APPLY sys.dm_os_volume_stats (mf.database_id, mf.file_id)
	LEFT JOIN sys.availability_databases_cluster AS adc ON sdb.group_database_id = adc.group_database_id
	LEFT JOIN sys.availability_groups AS ag ON adc.group_id = ag.group_id
	WHERE sdb.source_database_id IS NULL
), overview_cte AS ( 
SELECT
	[database_name]
	,ag_or_local
	,ag_name
	,drive
	,db_files_size_gb
	,db_file
	,SUM(db_files_size_gb) OVER (PARTITION BY [database_name] ORDER BY [database_name]) AS db_size_gb
	,SUM(db_files_size_gb) OVER (PARTITION BY drive,[database_name] ORDER BY drive,[database_name]) AS db_size_on_drive_perc
	,SUM(db_files_size_gb) OVER (PARTITION BY drive,ag_name ORDER BY drive,ag_name) AS ag_size_on_drive_gb
	,CAST((SUM(db_files_size_gb) OVER (PARTITION BY drive,ag_name ORDER BY drive,ag_name))/drive_size_gb*100.0 AS decimal(10,2)) AS ag_size_on_drive_perc
	,drive_size_gb
	,drive_free_space_gb
	,drive_free_space_perc
FROM drives_cte
)
 
SELECT DISTINCT
	drive
	,drive_size_gb
	,drive_free_space_gb
	,drive_free_space_perc
	,ag_name
	,ag_size_on_drive_gb
	,ag_size_on_drive_perc
	-- for detailed view (each DB) uncomment line below
	--,[database_name],db_file,DBSizeGB,db_size_on_drive_perc
FROM overview_cte
ORDER BY drive, ag_size_on_drive_perc DESC, ag_name;
