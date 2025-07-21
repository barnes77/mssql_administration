--On primary server to disable log shipping for particular database and secondary server
exec [master].dbo.sp_delete_log_shipping_primary_secondary
	@primary_database = N'primarydatabase'
	,@secondary_server = N'secondaryservername'
	,@secondary_database = N'secondarydatabase'
GO
--On primary server to delete primary database
exec [master].dbo.sp_delete_log_shipping_primary_database N'primarydatabase';
 
--On secondary server to delete secondary database
exec [master].dbo.sp_delete_log_shipping_secondary_database N'secondarydatabase';
