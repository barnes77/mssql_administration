#Get last 10 events of system shutting down from Kernel logs
Get-WinEvent -FilterHashTable @{LogName='System';ProviderName='Microsoft-Windows-Kernel-General'} | #Use [Kernel-General] logs ### No Filter
	Where-Object { $_.Message -like '*operating system is shutting down*' } | #Filter by a string
		Select-Object -First 10 -Property TimeCreated,Id,LevelDisplayName,Message #| Out-GridView
 
#Get last 10 events of system reboot initiated from User32 logs
Get-WinEvent -FilterHashTable @{LogName='System';ProviderName='User32'} | #Use [User32] logs ### No Filter
	Where-Object { $_.Message -like '*has initiated*' } | #Filter by a string
		Select-Object -First 10 -Property TimeCreated,Id,LevelDisplayName,Message #| Out-GridView
