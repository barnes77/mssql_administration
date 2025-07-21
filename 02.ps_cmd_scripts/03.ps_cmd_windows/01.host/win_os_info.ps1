<# Created by Mateusz Wierzbowski
Creation date: 2022/05/12
Aim: gather basic information about Host
Version: 2.0 #>
 
#Get basic information about Windows operating system
	$Os = Get-WmiObject -Class Win32_OperatingSystem | Select-Object -Property CSName,Caption,Version,Model
 
#Get basic information about processors
	$Procs1 = Get-WmiObject -Class Win32_Processor | Measure-Object  NumberOfLogicalProcessors,NumberOfCores -Sum | Select-Object -Property Property,@{Name='Value';Expression={$_.Sum}}
	$Procs2 = Get-WmiObject -Class Win32_Processor | Measure-Object -Average {MaxClockSpeed} | Select-Object -Property Property,@{Name='Value';Expression={$_.Average}}
 
#Get basic information about RAM
	$Memory = Get-WmiObject -Class Win32_ComputerSystem | Select-Object @{Name='Property';Expression={'TotalPhysicalMemoryGB'}},@{Name='Value';Expression={([math]::Round(($_.TotalPhysicalMemory/1GB),2))}}
 
#Get basic information about drives
	$DrivesSize = Get-WmiObject -Class Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3 } | Select-Object -Property @{Name='Device';Expression={$_.DeviceID+'\'}},@{Label="SizeGB";Expression={([math]::Round(($_.Size/1GB),2))}}, @{Label="FreeSpaceGB";Expression={([math]::Round(($_.FreeSpace/1GB),2))}}
 
#Get basic information about drives' formatting
	$DrivesFormat = Get-WmiObject -Query "SELECT Label, Blocksize, Name FROM Win32_Volume WHERE FileSystem='NTFS'" -ComputerName '.' | Select-Object -Property Name,Label,@{Label="BlockSizeKB";Expression={([math]::Round(($_.Blocksize/1KB),2))}}

#Combine information about drives
	$Drives = $DrivesSize | Select-Object Device,SizeGB,FreeSpaceGB,@{Name='FormattingKB';Expression={$tmp=$_.Device;($DrivesFormat | Where-Object Name -eq $tmp).BlockSizeKB}} | Sort-Object -Property Device
 
#Get all results 
	$Os | Format-Table
	$Procs1+$Procs2+$Memory | Format-Table
	$Drives | Format-Table
