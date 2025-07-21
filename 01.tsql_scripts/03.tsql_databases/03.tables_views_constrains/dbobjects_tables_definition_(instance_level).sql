/*
Created by: Mateusz Wierzbowski
Creation date: 2020/11/02
Aim: Gather definition of table for all tables on the instance
*/
USE tempdb;
SET NOCOUNT ON;
 
IF OBJECT_ID('#dba_table_def','U') IS NOT NULL BEGIN DROP TABLE #dba_table_def; END
IF OBJECT_ID('#dba_table_def2','U') IS NOT NULL BEGIN DROP TABLE #dba_table_def2; END
 
CREATE TABLE #dba_table_def (	
	table_name varchar(2000)
	,column_name nvarchar(128)
	,column_no int
	,data_type nvarchar(128)
	,chars_no int
	,nullable varchar(3)
	,column_def nvarchar(400)
	,table_type nvarchar(100)
);
CREATE TABLE #dba_table_def2 (	
	table_name varchar(2000)
	,table_def nvarchar(max)
);
 
exec sp_MSforeachdb '
USE ?
INSERT INTO #dba_table_def
SELECT
	iscol.table_catalog+''.''+iscol.table_schema+''.''+iscol.table_name AS table_name
	,iscol.column_name AS column_name
	,iscol.ordinal_position AS column_no
	,iscol.data_type AS [DataType]
	,iscol.character_maximum_length AS [chars_no]
	,iscol.is_nullable AS [nullable]
	,iscol.column_name + '' '' + data_type +
		CASE WHEN iscol.character_maximum_length IS NULL THEN '''' ELSE ''(''+CAST(iscol.character_maximum_length AS nvarchar(20))+'')'' END+
		CASE WHEN iscol.is_nullable = ''NO'' THEN '''' ELSE '' NULL'' END
		AS column_def
	,istab.table_type
FROM information_schema.columns AS iscol
LEFT JOIN information_schema.tables AS istab
	ON iscol.table_catalog = istab.table_catalog AND iscol.table_schema = istab.table_schema AND iscol.table_name = istab.table_name';
 
DECLARE @v1 varchar(2000),@v2 varchar(2000), @v3 nvarchar(4000);
DECLARE crsr CURSOR LOCAL FAST_FORWARD FOR
	SELECT table_name, table_type FROM #dba_table_def
 
OPEN crsr;
	FETCH NEXT FROM crsr INTO @v1, @v2
	WHILE @@FETCH_STATUS=0 BEGIN
	SET @v3 = ''
	SELECT @v3 = @v3 + CHAR(13)+ ','+column_def FROM #dba_table_def WHERE table_name=@v1
	SELECT @v3 = CASE WHEN @v3 = '' THEN '' ELSE SUBSTRING(@v3,3,LEN(@v3)-2) END
	INSERT INTO #dba_table_def2 VALUES ( @v1, 'CREATE'+CASE WHEN @v2 LIKE '%TABLE%' THEN ' TABLE ' ELSE ' VIEW 'END+@v1+' ( '+@v3+' )')
		FETCH NEXT FROM crsr INTO @v1, @v2;
	END
CLOSE crsr;
DEALLOCATE crsr;
 
--Uncomment this to get definition of each column info
--SELECT * FROM #dba_table_def ORDER BY table_name, column_no;
SELECT DISTINCT table_name,table_def FROM #dba_table_def2;
 
DROP TABLE #dba_table_def;
DROP TABLE #dba_table_def2;
