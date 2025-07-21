--Step01: Set Database to restricted user
ALTER DATABASE YourDB SET RESTRICTED_USER WITH ROLLBACK IMMEDIATE;
--Step02: Change logical files' names
ALTER DATABASE [YourDB] MODIFY FILE (NAME=N'YourDB_logicalMDF_file', NEWNAME=N'YourNEWDB_logicalMDF_file');
ALTER DATABASE [YourDB] MODIFY FILE (NAME=N'YourDB_logicalMDF_file', NEWNAME=N'YourNEWDB_logicalNDF_file');
ALTER DATABASE [YourDB] MODIFY FILE (NAME=N'YourDB_logicalLDF_file', NEWNAME=N'YourNEWDB_logicalLDF_file');
--Step03: Take database offline
ALTER DATABASE [YourDB] SET OFFLINE WITH ROLLBACK IMMEDIATE;
--Step04: change filepaths in DB properties
ALTER DATABASE [YourDB] MODIFY FILE ( NAME = YourNEWDB_logicalMDF_file, FILENAME = 'Path_to_mdf_file' );
ALTER DATABASE [YourDB] MODIFY FILE ( NAME = YourNEWDB_logicalNDF_file, FILENAME = 'Path_to_ndf_file' );
ALTER DATABASE [YourDB] MODIFY FILE ( NAME = YourNEWDB_logicalLDF_file, FILENAME = 'Path_to_ldf_file' );
--Step05: bring DB online and change user access to multi_user
ALTER DATABASE [YourDB] SET ONLINE;
ALTER DATABASE [YourDB] SET MULTI_USER;
--Step06: perform check
SELECT
	[name]
	,state_desc
	,user_access_desc
FROM sys.databases
WHERE [name] = 'YourDB';
