#.\zip_sys_dbs.ps1 -Sql_Instance servername\instance -Restart yes
#.\zip_sys_dbs.ps1 -Sql_Instance servername\instance -Restart no
<#
Created by Mateusz Wierzbowski
Creation date: 2021/03/09-12
Aim: create a zip file of copies of physical files of system databases - REQUIRES DOWNTIME

V1.0: 2021/03/09-12
V2.0: 2021/11/03
#>

<# PART 00 - Create params, check if the script is run by admin, check version of .Net, verify name of the instance #>
#Create params
Param(
	[Parameter(Mandatory=$true)] [string]$Sql_Instance, #instancename
	[Parameter(Mandatory=$true)] [string]$Restart #start instance afterwards?
)
#Verify if the script is run as admin
If(([Security.Principal.WindowsIdentity]::GetCurrent().Groups -contains 'S-1-5-32-544') -eq $false){
	Throw 'The script needs to be run as administrator.'
}

#Find .Net version
If((Test-Path "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full") -eq $true){
	$Net45 = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full").Release
}
If((Test-Path "HKLM:\Software\Microsoft\NET Framework Setup\NDP\v4\Full") -eq $true){
	$Net40 = (Get-ItemProperty "HKLM:\Software\Microsoft\NET Framework Setup\NDP\v4\Full").Install
}
If((Test-Path "HKLM:\Software\Microsoft\NET Framework Setup\NDP\v3.5") -eq $true){
	$Net35 = (Get-ItemProperty "HKLM:\Software\Microsoft\NET Framework Setup\NDP\v3.5").Install
}
If((Test-Path "HKLM:\Software\Microsoft\NET Framework Setup\NDP\v3.0\Setup") -eq $true){
	$Net30 = (Get-ItemProperty "HKLM:\Software\Microsoft\NET Framework Setup\NDP\v3.0\Setup").InstallSuccess
}
If(($Net45 -ge 378389) -or ($Net40 -eq 1) -or ($Net35 -eq 1) -or ($Net30 -eq 1)){
	$Net = 1
}
Else{
	$Net = 0
}

#Convert instance name provided into separate variable and perform a check on the naming convention of the instance
If(($Sql_Instance.Length - $Sql_Instance.Replace("/","\").Replace("\","").Length) -gt 1){
	Write-Error ("Instance name provided includes multiple backslashes and/or slashes") -ErrorAction Stop
}
Elseif($Sql_Instance.Contains("\")){
	$Server_Name = ($Sql_Instance.Split("\")[0].ToLower())
	$Instance_Name = ($Sql_Instance.Split("\")[1].ToLower())
}
Elseif($Sql_Instance.Contains("/")){
	$Server_Name = ($Sql_Instance.Split("/")[0].ToLower())
	$Instance_Name = ($Sql_Instance.Split("/")[1].ToLower())
}
	Else{
	$Server_Name = $Sql_Instance.ToLower()
	$Instance_Name = "mssqlserver"
}
Write-Host "`nName of SQL instance adjusted to syntax"$Server_Name"\"$Instance_Name

<# PART 01 - Get instance id and verify service account #>
#Get instance ID from Registry - if ID is missing, exit and print an error
Write-Host "`n`tRetrieving instance ID from Registry."
If((Test-Path -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\') -eq $false){
	Write-Error "No SQL instance found on the server." -ErrorAction Stop
}
Else{
	$Instance_Id = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL').$Instance_Name
	If(!$Instance_Id){
		Write-Error ("Instance ID not found in the registry. Correct instance name and rerun the script.") -ErrorAction Stop
	}
}
Write-Host "Instance ID retrieved."

#Get instance details from Registry
Write-Host "`n`tGetting instance details from Registry."
$Instance_Bin = (Get-ItemProperty -Path ("HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\" + $Instance_Id + "\Setup" )).SqlBinRoot
$Instance_Data = (Get-ItemProperty -Path ("HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\" + $Instance_Id + "\Setup" )).SqlDataRoot
$Is_Clustered = (Get-ItemProperty -Path ("HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\" + $Instance_Id + "\ClusterState")).SQL_Engine_Core_Inst
Write-Host "Details gathered."

#Perform a check of the service account - if the password is expired, exit and print an error
Write-Host "`n`tFinding svc account name for the SQL instance."
If($Instance_Name -eq "mssqlserver"){
	$Svc_Acc = Get-WmiObject win32_service | Where-Object {$_.Name -eq 'MSSQLSERVER'} | Select-Object -ExpandProperty StartName
	}
Else{
	$Svc_Acc = Get-WmiObject win32_service | Where-Object {$_.Name -eq 'MSSQL$'+$Instance_Name.ToUpper()} | Select-Object -ExpandProperty StartName
}
#Checking if Svc Account is LocalSystem
If($Svc_Acc -like 'LocalSystem*'){
	Write-Host "Service account "$Svc_Acc" is a local account - no checks needed. Consider changing it in the future."
}
#Checking if Svc Account is a virtual account
Elseif($Svc_Acc -like 'NT Service*'){
	Write-Host "Service account "$Svc_Acc" is a virtual account - no checks needed."
}
#Checking if Svc Account is an MSA account
Elseif($Svc_Acc -like '*$'){
	Write-Host "Service account "$Svc_Acc" is an MSA account - no checks needed."
}
#Checking if Svc Account is an AD account
Else{
	If(!(Get-Module -name ActiveDirectory) -eq $true) {
		Write-Host "`tNo ActiveDirectory module for PowerShell installed on the host. Attempting to complete the checks with net user."
				$Start = $Svc_Acc.IndexOf('\')+1
				$Len = $Svc_Acc.Length-$Svc_Acc.IndexOf('\')-1
				$User = $Svc_Acc.Substring($Start,$Len)
				$Acc_Status = net user $User /DOMAIN | Select-String "Account active"
				$Pwd_Exp01 = net user $User /DOMAIN | Select-String "Password expires"
				If($Pwd_Exp01 -notlike "*Never"){
					$Pwd_Exp02=[datetime]($Pwd_Exp01.Line.Substring(29,20))
					$Pwd_Exp03 = Get-Date $Pwd_Exp02 -format "yyyy-MM-dd HH-mm-ss"
				}
				$Today = Get-Date -format "yyyy-MM-dd HH-mm-ss"
			If(($Acc_Status -notlike '*Yes*') -or (($Pwd_Exp01 -notlike "*Never") -and ($Pwd_Exp03 -le $Today))){
			Write-Error "Service account for the SQL instance is AD account and is either locked out or password is expired. Consider fixing service account first." -ErrorAction Stop
			}
			Write-Host "Service account is an AD account - no issues with account found."
	}
	Else{
		$Acc_Status = Get-AdUser -Identity $Svc_Acc | Select-Object -ExpandProperty Enabled
		$Pwd_Exp01 = Get-AdUser -Identity $Svc_Acc | Select-Object -ExpandProperty PasswordExpired
		If(($Acc_Status -ne "True") -or ($Pwd_Exp01 -eq "True")){
			Write-Error "Service account for the SQL instance is AD account and is either locked out or password is expired. Consider fixing service account first." -ErrorAction Stop
		}
		Write-Host "Service account is an AD account - no issues with account found."
	}
}

<# PART 02 - Stop SQL service #>

#Stop a local instance
If($Is_Clustered -eq 0){
Write-Host "`n`tInstance is not clustered. Attempting to stop the instance."
	If($Instance_Name -eq "mssqlserver"){
		Stop-Service -Name MSSQLSERVER -Force -ErrorAction Stop
		}
	Else{
		Stop-Service -Name ("MSSQL$"+$Instance_Name.ToUpper()) -Force -ErrorAction Stop
	}
Write-Host "Instance is stopped."
}
#Stop a clustered instance
Else{
	#Get PS Module for clustering if absent from the host
	Write-Host "`n`tInstance is clustered. Getting PS module for FailoverCluster if there is none on the host."
	If(!(Get-Module -name FailoverClusters)){Import-Module FailoverClusters -Force -ErrorAction Stop | Out-Null}
	#Find preferred node
	Write-Host "`tFinding the preferred node for the resource group."
	$Pref_Node = ((Get-ClusterOwnerNode -Group $Server_Name | Select-Object -Property OwnerNodes).OwnerNodes | Where-Object {$_.State -eq "Up"} | Select-Object -Property Name -First 1).Name
	If(!$Pref_Node){
		Write-Host "`tNo preferred node is set."
	}
	Else{
		Write-Host "`tPreferred node is found."
	}
	
	#Check if the current node is the active node
	If(((Get-ClusterGroup | Where-Object {$_.Name -eq $Server_Name}).OwnerNode.name) -eq $env:computername){
		#If yes, take SQL Server service cluster resource offline
		Write-Host "`tIf the current node is the active node, attempting to stop the cluster resource group."
		Get-ClusterResource | Where-Object {$_.Name -like ("*("+ $Instance_Name + ")*") -and $_.ResourceType -eq "SQL Server"} | Stop-ClusterResource -ErrorAction Stop | Out-Null
		Write-Host "Instance stopped."
	}
	Else{
		#If no, take SQL Server service cluster resource offline and move it to current node
		Write-Host "`tIf the current node is not the active node, attempting to stop the cluster resource group and move it to the current node."
		Get-ClusterResource | Where-Object {$_.Name -like ("*("+ $Instance_Name + ")*") -and $_.ResourceType -eq "SQL Server"} | Stop-ClusterResource -ErrorAction Stop | Out-Null
		Move-ClusterGroup -Name $Server_Name -Node $env:computername -ErrorAction Stop | Out-Null
		Write-Host "Instance stopped."
	}
}

<# PART 03 - Copy physical files and zip them #>
#Create a folder to copy system databases to
Write-Host "`n`tCreating a temporary folder to move system databases to."
$Target_File = "systemdb_" + (Get-Date -Format "yyyyMMdd_HHmm")
$Target_Path = $Instance_Data+"\"+$Target_File

If(Test-Path -Path $Target_Path){
	Write-Error "Target folder " + $Target_Path + "already exists." -ErrorAction Stop
}
Else{
	New-Item -Path $Target_Path -ItemType Directory -ErrorAction Stop | Out-Null
}
Write-Host "Folder created in Instance's data folder."

#Copy mdf and ldf of system databases to target folder
Write-Host "`n`tCopying physical files to the target folder."
(Get-ChildItem -Path $Instance_Data -Include master.mdf,mastlog.ldf,model*.mdf,model*.ldf,MSDBData.*,MSDBLog.* -Recurse) | Copy-Item -Destination $Target_Path -ErrorAction Stop | Out-Null
(Get-ChildItem -Path $Instance_Bin -Include mssqlsystemresource.* -Recurse) | Copy-Item -Destination $Target_Path -ErrorAction Stop | Out-Null
Write-Host "Copied."

#Zip the target folder
#Use PowerShell command for PS 5+
Write-Host "`n`tAttempting to zip the folder with physical files."
$Target_Zip = $Target_Path+".zip"
If($PSVersionTable.PSVersion.Major -ge 5){
	Compress-Archive -Path ($Target_Path+'\*') -DestinationPath $Target_Zip -ErrorAction Stop | Out-Null
	Remove-Item $Target_Path -Recurse -Force -ErrorAction Stop | Out-Null
}
#Use .Net for PS 3+ and .Net 3+
Elseif(($PSVersionTable.PSVersion.Major -ge 3) -and ($Net -eq 1)) {
	Add-Type -assembly "system.io.compression.filesystem"
	[io.compression.zipfile]::CreateFromDirectory($Target_Path, $Target_Zip)
	Remove-Item $Target_Path -Recurse -Force -ErrorAction Stop | Out-Null
}
Else{
	Write-Host "Cannot zip the target folder since PSVersion is lower than 3.0 or .Net Framework is lower than 3.0. System database files were copied to the target folder, consider zipping them manually."
}
Write-Host "Folder zipped."

<# PART 04 - Start an instance #>
#Start a local instance
If($Restart -eq "no"){
	Write-Host "`nInstance has not been started as per request."
}
Elseif(($Is_Clustered -eq 0) -and ($Restart -eq "yes")){
	Write-Host "`n`tInstance is not clustered. Attempting to start the instance."
	If($Instance_Name -eq "mssqlserver"){
		Start-Service -Name MSSQLSERVER -ErrorAction Stop
		Start-Service -Name SQLAgent -ErrorAction Stop
		}
	Else{
		Start-Service -Name ("MSSQL$"+$Instance_Name.ToUpper()) -ErrorAction Stop
		Start-Service -Name ("SQLAgent$"+$Instance_Name.ToUpper()) -ErrorAction Stop
	}
	Write-Host "Instance has been started."
}
#Start a clustered instance
Else{
	Write-Host "`n`tInstance is clustered."
	#Check if the current node is the preferred node
	If(($Pref_Node -eq $env:computername) -or (!$Pref_Node)){
		#If yes, bring the cluster resource up
		Write-Host "`tCurrent node is the preferred node or there's no preferred node. Attempting to start the cluster resource group."
		Get-ClusterResource | Where-Object {$_.Name -like ("*("+ $Instance_Name + ")*") -and $_.ResourceType -eq "SQL Server Agent"} | Start-ClusterResource -ErrorAction Stop | Out-Null
		Write-Host "Cluster resource group has been started."
	}
	Else{
		#If no, move the cluster group to preferred node and bring it up
		Write-Host "`tCurrent node is not the preferred node. Moving it to the cluster resource group to the preferred one and attempting to start it."
		Move-ClusterGroup -Name $Server_Name -Node $Pref_Node -ErrorAction Stop | Out-Null
		Get-ClusterResource | Where-Object {$_.Name -like ("*("+ $Instance_Name + ")*") -and $_.ResourceType -eq "SQL Server Agent"} | Start-ClusterResource -ErrorAction Stop | Out-Null
		Write-Host "Cluster resource group started."
	}
}

Write-Host "`nZipped physical files of system DBs are located at"
$Target_Zip 
