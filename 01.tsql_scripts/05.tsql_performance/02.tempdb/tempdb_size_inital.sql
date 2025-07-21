SET NOCOUNT ON;
 
SELECT
	saf.[name]
	,saf.[filename]
	,saf.size*8/1024 AS int_size_mb
	,dbf.size*8/1024 AS curr_size_mb
FROM [master].sys.sysaltfiles AS saf
LEFT JOIN tempdb.sys.database_files AS dbf ON saf.[filename] = dbf.physical_name
WHERE saf.[name] LIKE 'temp%'
ORDER BY saf.[name],saf.[filename];
