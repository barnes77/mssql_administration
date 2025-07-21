--01. Change database to SIMPLE
USE [master]
GO
ALTER DATABASE [database_name] SET RECOVERY SIMPLE WITH NO_WAIT
GO
 
--02. Create new filegroup
USE [master]
GO
ALTER DATABASE [database_name] ADD FILEGROUP [FileStreamGroup2] CONTAINS FILESTREAM 
GO
USE [database_name]
GO
IF NOT EXISTS (SELECT name FROM sys.filegroups WHERE is_default=1 AND name = N'FileStreamGroup2') ALTER DATABASE [database_name] MODIFY FILEGROUP [FileStreamGroup2] DEFAULT
GO
 
--03. Create new FileStream file
USE [master]
GO
ALTER DATABASE [database_name] ADD FILE ( NAME = N'FileName2', FILENAME = N'E:\FileName2' ) TO FILEGROUP [FileStreamGroup2]
GO
 
--04. Create new table with the index
USE [database_name]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FileStore2](
	[RowId] [uniqueidentifier] ROWGUIDCOL  NOT NULL,
	[File] [varbinary](max) FILESTREAM  NULL,
PRIMARY KEY CLUSTERED 
(
	[RowId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY] FILESTREAM_ON [FileStreamGroup2]
) ON [PRIMARY] FILESTREAM_ON [FileStreamGroup2]
GO
ALTER TABLE [dbo].[FileStore2] ADD  DEFAULT (newsequentialid()) FOR [RowId]
GO
 
--05. Copy data between tables
USE [database_name]
GO
 
INSERT INTO dbo.FileStore2
SELECT * FROM dbo.FileStore
 
--06. Cleanup
USE [database_name]
GO
DROP TABLE dbo.FileStore;
GO
DBCC SHRINKFILE (N'FileName' , EMPTYFILE)
GO
ALTER DATABASE [database_name] REMOVE FILE [FileName]
GO
ALTER DATABASE [database_name] REMOVE FILEGROUP [FileStreamGroup1]
GO
ALTER DATABASE [database_name] MODIFY FILE (NAME=N'FileName2', NEWNAME=N'FileName')
GO
ALTER DATABASE database_name MODIFY FILEGROUP FileStreamGroup2 NAME=FileStreamGroup1
GO
EXEC sp_rename 'FileStore2','FileStore'
GO
 
--07. Change database to FULL
USE [master]
GO
ALTER DATABASE [database_name] SET RECOVERY FULL WITH NO_WAIT
GO
