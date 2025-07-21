--To enable Broker in MSDB, stop the SQL Agent first and run:
ALTER DATABASE [msdb] SET ENABLE_BROKER;
--Start the SQL Agent
 
--To enable Broker in user databases
	--Enable Broker with rollback immediate (it will fail with no_wait)
	ALTER DATABASE [database] SET ENABLE_BROKER WITH ROLLBACK IMMEDIATE;
--OR
	--Set it to single user mode, enable Broker and set it back to multi user mode
	ALTER DATABASE [database] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	ALTER DATABASE [database] SET ENABLE_BROKER;
	ALTER DATABASE [database] SET MULTI_USER WITH ROLLBACK IMMEDIATE;
