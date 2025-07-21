/*
Created by: Mateusz Wierzbowski
Creation date: 2020/10/23
Modification date: 2024/10/29
Aim: Gather information about SQL security settings, information is retrieved from registry for backward compatibility
Compatibility: SQL2000-SQL2019
*/
SET NOCOUNT ON;
 
--Declare variables
DECLARE
	@inst_name nvarchar(100), @value VARCHAR(100),
	@reg_path_sm varchar (350), @reg_path_np varchar (350), @reg_path_via varchar (350), @reg_path_tcp varchar (350),
	@auth int, @sm_status int, @np_status int, @via_status int, @tcp_status int,
	@thumbprint nvarchar (500), @force_encryption int
--Set registry paths
SET @inst_name=CONVERT(nvarchar,ISNULL(SERVERPROPERTY('INSTANCENAME'),'MSSQLSERVER'))
	exec [master].dbo.xp_regread N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL', @inst_name, @value OUTPUT;
SET @reg_path_sm = 'SOFTWARE\Microsoft\Microsoft SQL Server\' + @value + '\MSSQLServer\SuperSocketNetLib\Sm';
SET @reg_path_np = 'SOFTWARE\Microsoft\Microsoft SQL Server\' + @value + '\MSSQLServer\SuperSocketNetLib\Np';
SET @reg_path_via = 'SOFTWARE\Microsoft\Microsoft SQL Server\' + @value + '\MSSQLServer\SuperSocketNetLib\Via';
SET @reg_path_tcp = 'SOFTWARE\Microsoft\Microsoft SQL Server\' + @value + '\MSSQLServer\SuperSocketNetLib\Tcp';
--Check values
exec [master].dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\Microsoft SQL Server\MSSQLServer', N'LoginMode', @auth output, 'no_output';
exec [master].dbo.xp_regread N'HKEY_LOCAL_MACHINE', @reg_path_sm, N'Enabled', @sm_status output, 'no_output';
exec [master].dbo.xp_regread N'HKEY_LOCAL_MACHINE', @reg_path_np, N'Enabled', @np_status output, 'no_output';
exec [master].dbo.xp_regread N'HKEY_LOCAL_MACHINE', @reg_path_via, N'Enabled', @via_status output, 'no_output';
exec [master].dbo.xp_regread N'HKEY_LOCAL_MACHINE', @reg_path_tcp, N'Enabled', @tcp_status output, 'no_output';
exec [master].dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\Microsoft SQL Server\MSSQLServer\SuperSocketNetLib\', N'Certificate', @thumbprint output, 'no_output';
exec [master].dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',N'Software\Microsoft\MSSQLServer\MSSQLServer\SuperSocketNetLib',N'ForceEncryption',@force_encryption output;
--Get results
SELECT
	CASE WHEN @auth = 1 THEN 'Windows' ELSE 'Mixed' END AS authentication_mode
	,CASE WHEN @sm_status = 1 THEN 'Enabled' ELSE 'Disabled' END AS [shared_memory]
	,CASE WHEN @np_status = 1 THEN 'Enabled' ELSE 'Disabled' END AS named_pipes
	,CASE WHEN @via_status = 1 THEN 'Enabled' ELSE 'Disabled' END AS via_protocol
	,CASE WHEN @tcp_status = 1 THEN 'Enabled' ELSE 'Disabled' END AS tcp_protocol
	,CASE WHEN @force_encryption = 1 THEN 'enforced' ELSE 'none' END AS encryption_forced
	,@thumbprint AS ssl_cert_thumbprint;
