CREATE index_type /* UNIQUE CLUSTERED NONCLUSTERED */ INDEX index_name /*comment: index name here*/
	ON object_name /*1-3 part name for the table here*/ ( column_names ) /*comment: column names here in sort-priority order*/ sort_order /* ASC DESC */
	INCLUDE ( column_names ) /*comment: include non-key columns here*/
	/* WHERE predicate_filter | comment: for filtered indexes only */
	WITH
		PAD_INDEX = ON
		,FILLFACTOR = 90 --exemplary value / change to any value 1-100
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
		,MAXDOP = 8 --exemplary value
	/* ON partition_scheme_name (column_name) | comment: use in case of partitioned tables */
	/* ON filegroup | comment: specifies filegroup where index will be placed */
	/* ON "default" | comment: "default" needs to be delimited; creates index on the same filegroup as the table/view */
	/* FILESTREAM_ON filestream_filegroup_name / partition_scheme_name / "NULL" */
