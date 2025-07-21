#Get uptime of the host
	Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object CSName,LastBootUpTime
 
#Set OS time according to another host
	net time \\hostnamehere /set /y
 
#Get PageFile size with PS
	Get-CimInstance Win32_PageFileSetting | Select-Object -Property Caption,InitialSize,MaximumSize
 
#Get basic information about Windows operating system
	Get-WmiObject -Class Win32_OperatingSystem | Select-Object -Property CSName,Caption,Version,Model
 
#Get basic information about processors
	$Procs1 = Get-WmiObject -Class Win32_Processor | Measure-Object  NumberOfLogicalProcessors,NumberOfCores -Sum | Select-Object -Property Property,Sum,Average
	$Procs2 = Get-WmiObject -Class Win32_Processor | Measure-Object -Average {MaxClockSpeed} | Select-Object -Property Property,Average
	$Procs1+$Procs2 | Format-Table
 
#Get basic information about RAM
	Get-WmiObject -Class Win32_ComputerSystem | Select-Object @{Name='TotalPhysicalMemoryGB';Expression={([math]::Round(($_.TotalPhysicalMemory/1GB),2))}} | Format-Table
 
#Get basic information about Drives
	Get-WmiObject -Class Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3 } | Format-Table DeviceID,@{Label="SizeGB";Expression={( [math]::Round(($_.Size/1GB),2))}}, @{Label="FreeSpaceGB";Expression={([math]::Round(($_.FreeSpace/1GB),2))}}
 
#Get basic information about drives' formatting
	Get-WmiObject -Query "SELECT Label, Blocksize, Name FROM Win32_Volume WHERE FileSystem='NTFS'" -ComputerName '.' | 
		Sort-Object Name | Format-Table Name,Label,@{Label="BlockSizeKB";Expression={([math]::Round(($_.Blocksize/1KB),2))}}
 
#Get list of all hotfixes on the Windows server
	Get-Hotfix | Sort-Object HotFixID -Desc | Format-Table HotFixID,Description,InstalledOn,Source,InstalledBy
 
#Get list of 10 last hotfixes on the Windows server
	(Get-Hotfix | Sort-Object HotFixID -Desc)[-1...10] | Format-Table HotFixID,Description,InstalledOn,Source,InstalledBy
