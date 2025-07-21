# Created by Mateusz Wierzbowski
# Creation date: 2019/01/31
# Modification date: 2022/07/12
# Aim: gather information about all old local backup files & patching setups on the server
 
#Checking drives
	$Drive_Letters = Get-WmiObject Win32_LogicalDisk | Select-Object -Expand DeviceID
 
#Creating a report file
	$Date = (Get-Date).ToString('yyyyMMdd_hhmmss')
 
#Choose output dir
	$OutPutDir = "E:\DBA\"
	$Report = "$OutPutDir\BackupFilesReport_"+$Date+".txt"
 
#Gathering data to the report file
	$Header = "Host $([char]0009) File Name $([char]0009) Creation Date $([char]0009) Size MB $([char]0009) Location"
	Write-Output $Header | Set-Content $Report
 
#Gather infor and create report
	(Get-ChildItem -Path $Drive_Letters -file -Include *.bak, *.trn, *KB*.exe -Recurse -ErrorAction SilentlyContinue)|
		Foreach-Object {$env:computername+$([char]0009)+$_.Name+$([char]0009)+$_.CreationTime+$([char]0009)+([math]::Round( ($_.Length/(8*1024*1024)) , 2 ))+$([char]0009)+$_.FullName}|Add-Content $Report
