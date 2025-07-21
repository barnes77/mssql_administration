--Reorganize
ALTER INDEX index_name /*comment: index name here or ALL*/ ON object_name /*1-3 part name for the table here*/
	REORGANIZE
		/*PARTITION = partition_number */ --comment: one or multiple partition numbers
		WITH
			LOB_COMPACTION = ON --for rowstore indexes
			COMPRESS_ALL_ROW_GROUPS = ON --for columnstore indexes
	
--Rebuild
ALTER INDEX index_name /*comment: index name here or ALL*/ ON object_name /*1-3 part name for the table here*/
	REBUILD
		/*PARTITION = partition_number --comment: one or multiple partition numbers
			WITH (single_partition_rebuild_index_option) */ --options for single partitions, not possible for XML indexes; possible options: SORT_IN_TEMPDB, MAXDOP = DOP_number, DATA_COMPRESSION
		/*PARTITION = ALL */ -- for all partitions
	WITH
		PAD_INDEX = ON
		,FILLFACTOR = 90 --change to any value 1-100
		,SORT_IN_TEMPDB = ON
		,IGNORE_DUP_KEY = ON
		,STATISTICS_NORECOMPUTE = OFF
		,STATISTICS_INCREMENTAL = OFF --for SQL Server 2014+
		,DROP_EXISTING = OFF
		,ONLINE = OFF
		--,RESUMABLE = OFF --for SQL Server 2019
		--,MAX_DURATION = 10 --for SQL Server 2019 with RESUMABLE ON
		,ALLOW_ROW_LOCKS = ON
		,ALLOW_PAGE_LOCKS = ON
		--,OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF --for SQL Server 2019
		,MAXDOP = 8
		,WAIT_AT_LOW_PRIORITY ( --for SQL 2014+
			MAX_DURATION = 0 MINUTES --or
			ABORT_AFTER_WAIT = NONE --SELF / BLOCKES
		)
 
--Set
ALTER INDEX index_name /*comment: index name here or ALL*/ ON object_name /*1-3 part name for the table here*/
	SET --used to change index options without rebuilding/reorganization
		ALLOW_ROW_LOCKS = ON
		,ALLOW_PAGE_LOCKS = ON
		,OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF
		,IGNORE_DUP_KEY = ON
		,STATISTICS_NORECOMPUTE = OFF
		,COMPRESSION_DELAY = 0 */
 
--Resume (for SQL2017+)
ALTER INDEX index_name /*comment: index name here or ALL*/ ON object_name /*1-3 part name for the table here*/
	RESUME
 
--Pause (for SQL2017+)
ALTER INDEX index_name /*comment: index name here or ALL*/ ON object_name /*1-3 part name for the table here*/
	PAUSE
 
--Abort (for SQL2017+)
ALTER INDEX index_name /*comment: index name here or ALL*/ ON object_name /*1-3 part name for the table here*/
	ABORT
 
--Disable
ALTER INDEX index_name /*comment: index name here or ALL*/ ON object_name /*1-3 part name for the table here*/
	DISABLE
