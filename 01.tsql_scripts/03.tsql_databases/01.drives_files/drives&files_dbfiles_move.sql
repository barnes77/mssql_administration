--Step01: set DB to restricted user and take it offline
ALTER DATABASE [YourDB] SET RESTRICTED_USER WITH ROLLBACK IMMEDIATE;
ALTER DATABASE [YourDB] SET OFFLINE WITH ROLLBACK IMMEDIATE;
--Step02: copy physical files manually
--Step03: change filepaths in DB properties
ALTER DATABASE [YourDB] MODIFY FILE ( NAME = YourDB_logicalMDF_file, FILENAME = 'Path_to_mdf_file' );
ALTER DATABASE [YourDB] MODIFY FILE ( NAME = YourDB_logicalNDF_file, FILENAME = 'Path_to_ndf_file' );
ALTER DATABASE [YourDB] MODIFY FILE ( NAME = YourDB_logicalLDF_file, FILENAME = 'Path_to_ldf_file' );
--Step04: bring DB online and change user access to multi_user
ALTER DATABASE [YourDB] SET ONLINE;
ALTER DATABASE [YourDB] SET MULTI_USER;
--Step05: perform check
SELECT
	[name]
	,state_desc
	,user_access_desc
FROM sys.databases
WHERE [name] = 'YourDB';
--Step06: delete old files manually
