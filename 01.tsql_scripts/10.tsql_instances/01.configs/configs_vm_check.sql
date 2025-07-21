SET NOCOUNT ON;
 
SELECT
	SERVERPROPERTY('ComputerNamePhysicalNetBIOS') AS hostname
	,virtual_machine_type
	,virtual_machine_type_desc
FROM sys.dm_os_sys_info
