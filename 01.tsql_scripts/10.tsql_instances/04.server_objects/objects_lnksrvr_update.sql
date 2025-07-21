SELECT [name],product,[provider],[data_source],[location] FROM sys.servers WHERE [name] = 'lnk_srvr_name'
EXEC sp_setnetname 'lnk_srvr_name', 'new_connection_string'
SELECT [name],product,[provider],[data_source],[location] FROM sys.servers WHERE [name] = 'lnk_srvr_name'
