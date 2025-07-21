#Get last 10 errors/warnings from SCOM on local host
Get-WinEvent -FilterHashTable @{LogName='Operations Manager';Level=1,2,3} -MaxEvent 100 | ### Use [Operations Manager] - SCOM events ### Filter for warnings / errors
		Select-Object -First 10 -Property TimeCreated,Id,LevelDisplayName,Message #Select last 10 events
 
#Get last 10 events of setting maintenance mode SBSMaint
Get-WinEvent -FilterHashTable @{LogName='Application';Id=512} -MaxEvent 100 | ### Use [Application] instead of [Operations Manager] ### Filter for SBS Maint start (id 512)
		Select-Object -First 10 -Property TimeCreated,Id,LevelDisplayName,Message #Select last 10 events
 
#Get last 10 monitoring errors on local host
Get-WinEvent -FilterHashTable @{LogName='Operations Manager';Level=1,2,3;Id=4221} -MaxEvent 100 | ### Use [Operations Manager] - SCOM events ### Filter for monitoring errors (id 4221)
	Select-Object -First 10 -Property TimeCreated,Id,LevelDisplayName,Message #Select last 10 events
 
#Get last 10 monitoring errors on local host (AV blocking scripts)
Get-WinEvent -FilterHashTable @{LogName='Operations Manager';Level=1,2,3;Id=21414} -MaxEvent 100 | ### Use [Operations Manager] - SCOM events ### Filter for AV blocking scripts (id 21414)
	Select-Object -First 10 -Property TimeCreated,Id,LevelDisplayName,Message #Select last 10 events
 
#Get last 10 monitoring events 1201 (New MP received) and 1210 (New configuration became available)
Get-WinEvent -FilterHashTable @{LogName='Operations Manager';Id=1201,1210} -MaxEvent 100 | ### Use [Operations Manager] - SCOM events ### Filter for events 1201 and 1210
	Select-Object -First 10 -Property TimeCreated,Id,LevelDisplayName,Message #Select last 10 events
