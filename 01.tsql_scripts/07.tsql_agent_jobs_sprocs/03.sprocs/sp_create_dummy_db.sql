SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE sp_create_dummy_db
AS
BEGIN
	SET NOCOUNT ON;
	/*
	Created by: Mateusz Wierzbowski
	Creation date: 2021/07/28
	Aim: Create dummy DB with one table
	*/
	DECLARE @number int = FLOOR(RAND()*(10000-1)+1)
		,@new_db_name sysname
		,@sql nvarchar(max)
		,@sql2 nvarchar(max)
		,@sql3 nvarchar(max)
 
	IF EXISTS (SELECT * FROM sys.databases WHERE name = @new_db_name)
		BEGIN
			SET @number = @number+1
			SELECT @new_db_name = CONCAT('lstest_',@number)
		END
	ELSE
		BEGIN
			SELECT @new_db_name = CONCAT('lstest_',@number)
		END
 
	SET @sql =
	'CREATE DATABASE '+@new_db_name+'
	 CONTAINMENT = NONE
	 ON PRIMARY
	( NAME = N'''+@new_db_name+''', FILENAME = N''E:\MW_Data\'+@new_db_name+'.mdf'' , SIZE = 8192KB , FILEGROWTH = 65536KB )
	 LOG ON
	( NAME = N'''+@new_db_name+'_log'', FILENAME = N''F:\MW_Log\'+@new_db_name+'_log.ldf'' , SIZE = 8192KB , FILEGROWTH = 65536KB )';
	SET @sql2 =
	'USE ['+@new_db_name+']
	IF NOT EXISTS (SELECT name FROM sys.filegroups WHERE is_default=1 AND name = N''PRIMARY'') ALTER DATABASE ['+@new_db_name+'] MODIFY FILEGROUP [PRIMARY] DEFAULT';
	SET @sql3 =
	'USE ['+@new_db_name+']
	CREATE TABLE dbo.DummyTable (foo nvarchar(30),bar nvarchar(30), timestamp nvarchar(30));
			DECLARE @i int = 0
			DECLARE @j int = 1000
			WHILE @i < @j
			BEGIN
				INSERT INTO dbo.DummyTable
				VALUES (''foo'',''bar'',CONVERT(nvarchar(30),getdate(),121))
				SELECT @i = @i + 1
			END';
	exec (@sql);
	exec (@sql2);
	exec (@sql3);
END
GO
