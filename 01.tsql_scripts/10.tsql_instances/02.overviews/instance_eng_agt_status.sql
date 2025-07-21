SELECT
	(SELECT create_date FROM sys.databases WHERE database_id = 2) AS instance_boot_time,
	(SELECT [status_desc] FROM sys.dm_server_services WHERE [servicename] LIKE N'SQL Server Agent (%') AS agent_status
--WHERE @@SERVERNAME LIKE '%PR%'; --Common part of Prod instances when running via registered servers
--WHERE @@SERVERNAME NOT LIKE '%PR%'; --Common part of Prod instances when running via registered servers
--WHERE @@SERVERNAME = ''; --Exact name of the instance when running via registered servers
--WHERE @@SERVERNAME IN ('',''); --Exact names of the instances when running via registered servers
