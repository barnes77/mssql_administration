SELECT
	 'USE [' + sdb.[name] + N']' + CHAR(13) + CHAR(10)
	+ 'DBCC SHRINKFILE (N''' + mf.[name] + N''' , 0, TRUNCATEONLY);'
	+ CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)
FROM sys.master_files AS mf
JOIN sys.databases AS sdb ON mf.database_id = sdb.database_id
WHERE sdb.database_id > 4 AND mf.[file_id] = 2;
