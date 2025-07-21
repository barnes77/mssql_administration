/*
Created by: Mateusz Wierzbowski
Creation date: 2021/01/14
Aim: Prepare table that can be copied as CSV file
*/
SET NOCOUNT ON;
 
IF OBJECT_ID('#dba_export_csv','U') IS NOT NULL BEGIN DROP TABLE #mptw_export; END
CREATE TABLE #dba_export_csv (
	[line] nvarchar(2000)
);
 
DECLARE @int nvarchar(60), @int2 nvarchar(400), @sql nvarchar(2000), @table nvarchar(200);
 
SET @table = 'TableName'; --insert table_name here
 
SET @int = '';
SELECT @int = @int + ';' + column_name FROM information_schema.columns WHERE table_name = @table ORDER BY ordinal_position;
SET @int = RIGHT(@int,LEN(@int)-1);
 
SET @int2 = '';
SELECT @int2 = @int2 + '+;+' +
	CASE
		WHEN data_type NOT IN ('bit','int','smalldatetime','ntext') THEN column_name
		WHEN data_type IN ('bit','int') THEN 'CAST('+column_name+' as nvarchar(20))'
		WHEN data_type = 'smalldatetime' THEN 'CONVERT(nvarchar,'+column_name+',120)'
		WHEN data_type = 'ntext' THEN 'CAST('+column_name+' as nvarchar(2000))'
	END
FROM information_schema.columns
WHERE TABLE_NAME = @table ORDER BY ordinal_position;
SET @int2 = RIGHT(@int2,LEN(@int2)-3);
SET @int2 = REPLACE(@int2,'+;+','+'';''+');
 
INSERT INTO #dba_export_csv
SELECT @int;
 
SET @sql = 'INSERT INTO #dba_export_csv SELECT '+@int2+'FROM '+@table+' ORDER BY 1 ASC'; --change column for ordering
exec (@sql);
 
SELECT * FROM #dba_export_csv;
 
DROP TABLE #dba_export_csv;
