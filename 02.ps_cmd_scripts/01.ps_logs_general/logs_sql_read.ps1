#Get last 10 errors from SQL Server Logs
Get-WinEvent -FilterHashTable @{LogName='Application';ProviderName='MSSQL$MWSQL11';Level=1,2,3} -MaxEvent 100 | ### Change ID of the instance in ProviderName ### Filter for warnings / errors
	Select-Object -First 10 -Property TimeCreated,Id,LevelDisplayName,Message
 
#Get last 10 events of start up from SQL Server Logs
Get-WinEvent -FilterHashTable @{LogName='Application';ProviderName='MSSQL$MWSQL11'} -MaxEvent 10000 | ### Change ID of the instance in ProviderName ### No Filter
	Where-Object { $_.Message -like '*SQL Server is starting*' -and $_.Message -notlike '*local availability replica*' } | #Filter by a string
		Select-Object -First 10 -Property TimeCreated,Id,LevelDisplayName,Message
 
#Get last 10 events of shut down from SQL Server Logs
Get-WinEvent -FilterHashTable @{LogName='Application';ProviderName='MSSQL$MWSQL11'} -MaxEvent 10000 | ### Change ID of the instance in ProviderName ### No Filter
	Where-Object { $_.Message -like '*SQL Trace was stopped due to server shutdown*' } | #Filter by a string
		Select-Object -First 10 -Property TimeCreated,Id,LevelDisplayName,Message
 
#Get last 10 events from SQL Server Logs based on string
Get-WinEvent -FilterHashTable @{LogName='Application';ProviderName='MSSQL$MWSQL11'} -MaxEvent 10000 | ### Change ID of the instance in ProviderName ### No Filter
	Where-Object { $_.Message -like '*string_here*' } | #Filter by a string
		Select-Object -First 10 -Property TimeCreated,Id,LevelDisplayName,Message
