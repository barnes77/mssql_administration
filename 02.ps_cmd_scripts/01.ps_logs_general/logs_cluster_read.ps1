#Get last 10 errors/warnings from WSFC on current node
Get-WinEvent -ComputerName $env:computername -FilterHashTable @{LogName='System';ProviderName='Microsoft-Windows-FailoverClustering';Level=1,2,3} -MaxEvent 100 | ### Filter for warnings / errors
		Select-Object -First 10 -Property TimeCreated,Id,LevelDisplayName,Message #Select last 10 events
 
#Get last 10 errors/warnings from WSFC on another node (replace SecondNodeDNS with hostname in -ComputerName)
Get-WinEvent -ComputerName SecondNodeDNS -FilterHashTable @{LogName='System';ProviderName='Microsoft-Windows-FailoverClustering';Level=1,2,3} -MaxEvent 100 | ### Filter for warnings / errors
		Select-Object -First 10 -Property TimeCreated,Id,LevelDisplayName,Message #Select last 10 events


#TimeSpan: value given in minutes
#$env:TEMP will save data to %temp%
Get-ClusterLog -Destination $env:TEMP -TimeSpan 1440 -UseLocalTime -Node node1name,node2name -SkipClusterState
