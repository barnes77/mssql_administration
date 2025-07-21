
USE tempdb;
SET NOCOUNT ON;
 
IF OBJECT_ID('#dbcc_results','U') IS NOT NULL BEGIN DROP TABLE #dbcc_results; END
 
CREATE TABLE #dbcc_results (
	parentobject varchar(200)
	,[object] varchar(200)
	,[field] varchar(200)
	,[value] varchar(200)
	,[database_name] varchar(200) null,
	database_id smallint
);
 
DECLARE @id smallint,@db varchar(200),@cmd varchar(800);
 
DECLARE crsr CURSOR LOCAL FAST_FORWARD FOR
	SELECT [name], [database_id] FROM [master].sys.databases WHERE [state]=0 AND is_in_standby=0 AND is_read_only=0;
 
OPEN crsr;
	FETCH NEXT FROM crsr INTO @db, @id;
WHILE @@FETCH_STATUS=0 BEGIN
	SET @cmd='dbcc dbinfo('''+@db+''') with tableresults, no_infomsgs';
	INSERT INTO #dbcc_results(parentobject,[object],[field],[value])
		exec (@cmd);
	UPDATE #dbcc_results SET field=LOWER(LTRIM(field));
	DELETE FROM #dbcc_results WHERE field NOT IN ('dbi_dbcclastknowngood','dbi_dbccflags');
	UPDATE #dbcc_results SET [database_name]=@db, database_id=@id WHERE database_id IS NULL;
	FETCH NEXT FROM crsr INTO @db, @id;
END
CLOSE crsr;
DEALLOCATE crsr;
SELECT
	[database_name]
	,database_id
	,CAST(dbi_dbccflags AS tinyint) AS dbi_dbcc_flags
	,CONVERT(smalldatetime,dbi_dbcclastknowngood,121) AS dbi_dbcc_last_known_good
FROM (
	SELECT DISTINCT
		[database_name]
		,database_id
		,field
		,[value]
	FROM #dbcc_results
) AS pivot_source
PIVOT(
	max([value]) FOR field IN (dbi_dbccflags,dbi_dbcclastknowngood)
) AS pivot_table
WHERE [database_name] <> 'tempdb'
ORDER BY [database_name]
DROP TABLE #dbcc_results;
