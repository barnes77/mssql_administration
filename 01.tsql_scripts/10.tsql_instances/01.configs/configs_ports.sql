/*
Created by: Mateusz Wierzbowski
Creation date: 2020/10/23
Aim: Gather information about SQL ports, information is retrieved from registry for backward compatibility
Compatibility: SQL2000-SQL2019
*/
SET NOCOUNT ON;
 
--Declare variables
DECLARE @dyn_port nvarchar (10),@stat_port nvarchar (10)
--Check values
exec [master].dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\Microsoft SQL Server\MSSQLServer\SuperSocketNetLib\Tcp\IpAll', N'TcpDynamicPorts', @dyn_port output, 'no_output'
exec [master].dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\Microsoft SQL Server\MSSQLServer\SuperSocketNetLib\Tcp\IpAll', N'TcpPort', @stat_port output, 'no_output'
--Get results
SELECT
	@dyn_port AS dynamic_port
	,@stat_port AS static_port;
