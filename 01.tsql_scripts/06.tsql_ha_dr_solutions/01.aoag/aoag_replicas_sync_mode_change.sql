--change availability mode to synchronous
USE [master]
ALTER AVAILABILITY GROUP [AOAGName] MODIFY REPLICA ON N'instance name' WITH (AVAILABILITY_MODE = synchronous_commit);
ALTER AVAILABILITY GROUP [AOAGName] MODIFY REPLICA ON N'instance name2' WITH (AVAILABILITY_MODE = synchronous_commit);
 
--change availability mode to asynchronous
USE [master]
ALTER AVAILABILITY GROUP [AOAGName] MODIFY REPLICA ON N'instance name' WITH (AVAILABILITY_MODE = asynchronous_commit);
ALTER AVAILABILITY GROUP [AOAGName] MODIFY REPLICA ON N'instance name2' WITH (AVAILABILITY_MODE = asynchronous_commit);
