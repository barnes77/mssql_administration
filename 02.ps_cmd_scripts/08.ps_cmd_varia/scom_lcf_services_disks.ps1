# Create_LCFServicesAndDisks.ps1
# Created by Mateusz Wierzbowski
# Creation date: 07/02/2019
# Aim: Create LCF file for old (ATS2-SME1) SCOM to monitor disk and applications
# This is version v0.9 not tested on prod servers
 
#Checking drives
$Drive_Letters = Get-WmiObject Win32_LogicalDisk | Select-Object -Expand DeviceID
 
#Renaming any existing LCF files
Rename-Item -Path "C:\DBA\Localdisk.txt" -NewName "OLD_Localdisk.txt" -ErrorAction SilentlyContinue -Force
Rename-Item -Path "C:\DBA\Services.txt" -NewName "OLD_Services.txt" -ErrorAction SilentlyContinue -Force
 
#creating LCF files
$Lcf_File_Disk = "C:\DBA\Localdisk.txt"
$Lcf_File_Services = "C:\DBA\services.txt"
New-Item $Lcf_File_Disk -ItemType file -ErrorAction SilentlyContinue -Force
New-Item $Lcf_File_Services -ItemType file -ErrorAction SilentlyContinue -Force
 
#Creating LCF for disks except for C: with warning for less than 10% of free space and alert for less than 5%
$Drive_Letters | ForEach-Object {$_ + ";999999;10;999999;5;ZZ-Event.Database.MsSQL.Notify;2"}|
	Select-String -Pattern 'C:' -NotMatch|Set-Content $Lcf_File_Disk
 
#Creating LCF for services (SQL and Agent) with p2 priority for service offline
"Service;MSSQLSERVER;SQL Server (MSSQLSERVER);0;0;ZZ-Event.Database.MsSQL.Notify
Service;SQLSERVERAGENT;SQL Server Agent (MSSQLSERVER);0;0;ZZ-Event.Database.MsSQL.Notify"|Set-Content $Lcf_File_Services
