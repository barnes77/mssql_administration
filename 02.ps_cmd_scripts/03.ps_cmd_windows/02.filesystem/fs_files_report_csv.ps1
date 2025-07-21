# Created by Mateusz Wierzbowski
# Creation date: 2019/01/31
# Modification date: 2022/07/12
# Aim: gather information about all old local backup files & patching setups on the server
 
#Checking drives
	$Drive_Letters = Get-WmiObject Win32_LogicalDisk | Select-Object -Expand DeviceID
 
#Creating a report file
	$Date = (Get-Date).ToString('yyyyMMdd_hhmmss')
 
#Choose output dir
	$OutPutDir = "D:\DBA\"
	$Report = "$OutPutDir\BackupFilesReport_"+$Date+".csv"
 
#Gathering data to the report file
	$Header = "Host;File Name;Creation Date;Size MB;Location"
	Write-Output $Header | Set-Content $Report
 
#Gather infor and create report
	(Get-ChildItem -Path $Drive_Letters -file -Include *.bak, *.trn, *KB*.exe -Recurse -ErrorAction SilentlyContinue)|
		Foreach-Object {$env:computername+";"+$_.Name+";"+$_.CreationTime+";"+([math]::Round( ($_.Length/(8*1024*1024)) , 2 ))+";"+$_.FullName,$([char]0009)}|Add-Content $Report
