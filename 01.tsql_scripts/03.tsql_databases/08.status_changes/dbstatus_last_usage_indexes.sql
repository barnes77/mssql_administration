/*
Created by: Mateusz Wierzbowski
Creation date: 2020/09/30
V2.0: 2021/10/06
Aim: Check last connection time based on user's interaction with indexes
*/
SET NOCOUNT ON;
 
SELECT
	[database_name]
	,MAX(last_use) AS last_index_use
FROM
	(SELECT
		DB_NAME(database_id) AS [database_name]
		,MAX(last_user_lookup) AS last_user_lookup
		,MAX(last_user_scan) AS last_user_scan
		,MAX(last_user_seek) AS last_user_seek
		,MAX(last_user_update) AS last_user_update
	FROM sys.dm_db_index_usage_stats
	GROUP BY DB_NAME(database_id)
	) AS pivot_source
	UNPIVOT (
			last_use FOR last_index_interaction
			IN ([last_user_lookup],[last_user_scan],[last_user_seek],[last_user_update])
		) AS unpivot_table
GROUP BY [database_name]
ORDER BY [database_name];
