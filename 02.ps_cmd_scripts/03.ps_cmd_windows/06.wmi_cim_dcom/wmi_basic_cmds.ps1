#Verify WMI repositories and repair them
	winmgmt /verifyrepository %systemroot%\system32\wbem\repository
	winmgmt /salvagerepository
 
#Execute WMI query
	Get-WmiObject  -ComputerName 'FQDNOrServerName' -NameSpace 'root\NameSpace' -Query 'QueryHere' 
