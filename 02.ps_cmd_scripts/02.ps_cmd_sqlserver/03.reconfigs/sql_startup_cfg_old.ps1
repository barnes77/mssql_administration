<# 
Modified by Mateusz Wierzbowski
Date of modification: 2021/03/20
Aim:
	Configure CEIP services to disabled start
	Configure Browser to disabled start, if all SQL instances are listening on static ports
	Configure SQL services to a delayed auto start and retry on the failure #>
 
#Find all SQL related services on the host and list their start modes
Write-Host "Following SQL services are present on the host. They have following start modes configured"
Write-Host "(win32_service WMI class doesn't differentiate between AutomaticDelayed and Automatic start modes)."
$Sql_Services = (Get-WmiObject win32_service | Where-Object {$_.Name -like '*SQL*' -or $_.Name -like 'SQL*'}) | Select-Object -ExpandProperty Name
(Get-WmiObject win32_service | Where-Object {$_.Name -in $Sql_Services}) | Select-Object -Property Name,StartMode | Format-Table -AutoSize
 
#Request confirmation from user before proceeding
$Confirmation = Read-Host "Verify names of the services. If you see any services that shouldn't be altered, type 'no'. Do you want to proceed? [yes/no]"
If($Confirmation -eq "yes"){
 
	#Set AutomaticDelayedStart for every service, except for: Browser, Full-Text Daemon Launcher, CEIP
	$Pure_Sql_Services = $Sql_Services | Where-Object {$_ -notlike '*TELEME*' -and $_ -notlike '*FDLauncher*' -and $_ -notlike '*Browser*'}
	Foreach($Service in $Pure_Sql_Services) {
		sc.exe config $Service start= delayed-auto | Out-Null
		sc.exe failure $Service reset= 60 actions= restart/5000 | Out-Null
	}
 
	#Check if all instances are listening on static ports, if yes, set Browser to disabled
	$Browser_Service = $Sql_Services | Where-Object {$_ -like '*BROWSE*'}
	$Sql_Instances = $Sql_Services | Where-Object {$_ -like 'MSSQLSERVER' -or $_ -like 'MSSQL$*'}
	$i = 0
	$j = 0
	#Find instance ID to read registry and get static ports
	Foreach($Instance in $Sql_Instances){
		$j++
		If($Instance -like 'MSSQLSERVER'){
			$Instance_Id = $Instance
		}
		Else {
			$Len = $Instance.Length
			$Instance_Id = $Instance.Substring(6,$Len-6)
		}
		$Sql_Version = (Get-ItemProperty -Path ("HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\" + $Instance_Id + "\MSSQLServer\CurrentVersion\" )).CurrentVersion
		$Sql_Version = $Sql_Version.Substring(0,2)
		$Static_Port = (Get-ItemProperty -Path ("HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL"+$Sql_Version+"." + $Instance_Id + "\MSSQLServer\SuperSocketNetLib\Tcp\IPAll" )).TcpPort
		$Static_Port
		If(!$Static_Port -eq $false){$i++}
	}
	#Ask if start mode for Browser should be changed, if no instance is using static port
	If($i -eq 0){
		$Conf = Read-Host "No SQL instance listening on static port was found. Would you still like to set SQL Browser start mode to AutomaticDelayedStart? [yes/no]"
		If($Conf -eq "yes"){
			sc.exe config $Browser_Service start= delayed-auto | Out-Null
			sc.exe failure $Browser_Service reset= 60 actions= restart/5000 | Out-Null
			Write-Host "SQL Browser start mode was changed to AutomaticDelayedStart"
		}
		Else {
			$Startmode = (Get-WmiObject win32_service | Where-Object {$_.Name -eq $Browser_Service}) | Select-Object -ExpandProperty StartMode
			Write-Host "SQL Browser start mode was not changed - it's" $Startmode.ToLower()
		}
	}
	#Ask if start mode for Browser should be changed, if all instances are using static ports
	Else{
		If($i = $j){
			$Conf = Read-Host "All SQL instances are listening static ports. Would you like to set SQL Browser start mode to Disabled? [yes/no]"
			If($Conf -eq "yes"){
				sc.exe config $Browser_Service start= disabled | Out-Null
				Write-Host "SQL Browser start mode was changed to Disabled"
			}
			Else {
				$Startmode = (Get-WmiObject win32_service | Where-Object {$_.Name -eq $Browser_Service}) | Select-Object -ExpandProperty StartMode
				Write-Host "SQL Browser start mode was not changed - it's" $Startmode.ToLower()
			}
		}
 
	}
	#Set CEIP services to disabled start
	$Telemetry_Services = $Sql_Services | Where-Object {$_ -like '*TELEME*'}
	Foreach($Service in $Telemetry_Services) {
		sc.exe config $Service start= disabled | Out-Null
	}
 
	#Write a summary
	Write-Host "After changes SQL services on the host have following start modes "
	Write-Host "(win32_service WMI class doesn't differentiate between AutomaticDelayed and Automatic start modes)."
	(Get-WmiObject win32_service | Where-Object {$_.Name -in $Sql_Services}) | Select-Object -Property Name,StartMode | Format-Table -AutoSize
}
Else{
	Write-Host "No changes have been done."
}
