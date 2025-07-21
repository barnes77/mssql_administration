#.\sql_startup_cfg.ps1 -EnabledBrowser yes -SqlDelayed yes -Report yes
#.\sql_startup_cfg.ps1 -EnabledBrowser yes -SqlDelayed yes
#.\sql_startup_cfg.ps1 -EnabledBrowser no
#.\sql_startup_cfg.ps1

<# Created by Mateusz Wierzbowski
Creation date: 2022/07/22
Aim: Configure startup of SQL Services (for non-disabled)
	SQL instances and agents (standalone and alwayson replicas) >> automatic start and for SQL instances delayed start
	SQL instances and agents (clustered instances) >> manual start
	SSAS/SSIS/SSRS >> automatic start
	SQL Browser >> based on the input
	CEIP services >> disabled
#>

Param(
	[Parameter(Mandatory=$false)] [string]$EnabledBrowser,
	[Parameter(Mandatory=$false)] [string]$SqlDelayed,
	[Parameter(Mandatory=$false)] [string]$Report
)	
#Step01: Verify if the script is being run by an admin
If(([Security.Principal.WindowsIdentity]::GetCurrent().Groups -contains 'S-1-5-32-544') -eq $false){
	Throw 'The script needs to be run as administrator.' 
}

#Step02: Create functions
Function Test-RegistryValue { #source: www.jonathanmedd.net/2014/02/testing-for-the-presence-of-a-registry-key-and-value.html
	Param (
		[Parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()]$Path,
		[parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()]$Value
	)
	Try {
		Get-ItemProperty -Path $Path | Select-Object -ExpandProperty $Value -ErrorAction Stop | Out-Null
		Return $true
	}
	Catch {
		Return $false
	}
}
Function Get-ShortName {
	Param (
		[Parameter(Mandatory=$true)][string]$Service_Name
	)
	$Service_Name.Replace('MSSQL$','').Replace('SQLAgent$','').Replace('MSOLAP$','').Replace('MSSQLFDLauncher$','').Replace('ReportServer$','').Replace('SQLTELEMETRY$','').Replace('SSASTELEMETRY$','').Replace('SSRSTELEMETRY$','')
}
Function Get-ServiceType {
	Param (
		[Parameter(Mandatory=$true)][string]$Service_Name
	)
	If($Service_Name -like 'MSSQL$*' -or $Service_Name -eq 'MSSQLSERVER') {'SqlInstance'} 
		Elseif($Service_Name -like 'SQLAgent$*' -or $Service_Name -eq 'SQLSERVERAGENT') {'SqlAgent'} 
		Elseif($Service_Name -like 'MSOLAP$*') {'SsasInstance'} 
		Elseif($Service_Name -like '*MsDts*') {'SsisInstance'} 
		Elseif($Service_Name -like '*ReportServer*') {'SsrsInstance'} 
		Elseif($Service_Name -like '*FDLauncher*') {'FDLauncher'} 
		Elseif($Service_Name -eq 'SQLBrowser') {'SqlBrowser'} 
		Elseif($Service_Name -eq 'SQLWriter') {'SqlWriter'} 
		Elseif($Service_Name -like '*SQLTELEMETRY*') {'SqlTelemetry'} 
		Elseif($Service_Name -like '*SSASTELEMETRY*') {'SsasTelemetry'} 
		Elseif($Service_Name -like '*SSRSTELEMETRY*') {'SsrsTelemetry'} 
		Elseif($Service_Name -like '*DTC*') {'Dtc'} ##testing
		Else {'Other'}
}
Function Get-InstanceId {
	Param (
		[Parameter(Mandatory=$true)][string]$Service_Name
	)

	If((Get-ServiceType -Service_Name $Service_Name) -in ('SqlInstance','SqlAgent')) {
		$Instance_Name = Get-ShortName -Service_Name $Service_Name
		(Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL').$Instance_Name
	}
}
Function Get-IsClustered {
	Param (
		[Parameter(Mandatory=$true)][string]$Service_Name
	)

	If((Get-ServiceType -Service_Name $Service_Name) -in ('SqlInstance','SqlAgent')) {
		$Instance_Id = Get-InstanceId -Service_Name $Service_Name
		(Get-ItemProperty -Path ("HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\" + $Instance_Id + "\ClusterState")).SQL_Engine_Core_Inst
	}
	If((Get-ServiceType -Service_Name $Service_Name) -eq 'Dtc') { ##testing
		If((Test-Path -Path "HKLM:\Cluster\ResourceTypes\Distributed Transaction Coordinator") -eq $true){
			1
		}
	}
}
Function Get-IsHadr {
	Param (
		[Parameter(Mandatory=$true)][string]$Service_Name
	)

	If((Get-ServiceType -Service_Name $Service_Name) -eq 'SqlInstance') {
		$Instance_Id = Get-InstanceId -Service_Name $Service_Name
		If((Test-Path -Path ("HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\" + $Instance_Id + "\MSSQLServer\HADR")) -eq $true){
			(Get-ItemProperty -Path ("HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\" + $Instance_Id + "\MSSQLServer\HADR")).HADR_Enabled
		}
		Else {
			0
		}
	}
}
Function Get-ClusterSqlName {
	Param (
		[Parameter(Mandatory=$true)][string]$Service_Name
	)
	Try {
		If(!(Get-Module -name FailoverClusters)){Import-Module FailoverClusters -Force -ErrorAction Stop}
	}
	Catch {
		$Error_Message = $_.Exception
	}
	If((Get-IsClustered -Service_Name $Service_Name) -eq 1 -and (Get-ServiceType -Service_Name $Service_Name) -eq 'SqlInstance'){
		If($Error_Message -notlike '*specified module ''FailoverClusters'' was not loaded*'){
			$Instance_Id = Get-InstanceId -Service_Name $Service_Name
			(Get-ItemProperty -Path ("HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\" + $Instance_Id + "\Cluster")).ClusterName
		}
	}
	If((Get-IsClustered -Service_Name $Service_Name) -eq 1 -and (Get-ServiceType -Service_Name $Service_Name) -eq 'Dtc'){ ##testing
		If($Error_Message -notlike '*specified module ''FailoverClusters'' was not loaded*'){
			(Get-ItemProperty -Path "HKLM:\Cluster\ResourceTypes\Distributed Transaction Coordinator").ClusterDefaultVirtualServer
		}
	}
}
Function Get-SqlPrefferedNode {
	Param (
		[Parameter(Mandatory=$true)][string]$Service_Name
	)
	Try {
		If(!(Get-Module -name FailoverClusters)){Import-Module FailoverClusters -Force -ErrorAction Stop}
	}
	Catch {
		$Error_Message = $_.Exception
	}
	If((Get-IsClustered -Service_Name $Service_Name) -eq 1){
		If($Error_Message -notlike '*specified module ''FailoverClusters'' was not loaded*'){
			$Cluster_Sql_Name = Get-ClusterSqlName -Service_Name $Service_Name
			$Cluster_Role = (Get-ClusterResource | Where-Object { $_.Name -match $Cluster_Sql_Name -and $_.ResourceType -eq 'Network Name'}).OwnerGroup
			((Get-ClusterOwnerNode -Group $Cluster_Role | Select-Object -Property OwnerNodes).OwnerNodes | Where-Object {$_.State -eq "Up"} | Select-Object -Property Name -First 1).Name
			}
		}
}
Function Get-SqlCurrentNode {
	Param (
		[Parameter(Mandatory=$true)][string]$Service_Name
	)
	Try {
		If(!(Get-Module -name FailoverClusters)){Import-Module FailoverClusters -Force -ErrorAction Stop}
	}
	Catch {
		$Error_Message = $_.Exception
	}
	If((Get-IsClustered -Service_Name $Service_Name) -eq 1){
		If($Error_Message -notlike '*specified module ''FailoverClusters'' was not loaded*'){
			$Cluster_Sql_Name = Get-ClusterSqlName -Service_Name $Service_Name
			$Cluster_Role = (Get-ClusterResource | Where-Object { $_.Name -match $Cluster_Sql_Name -and $_.ResourceType -eq 'Network Name'}).OwnerGroup
			(Get-ClusterGroup | Where-Object {$_.Name -eq $Cluster_Role }).OwnerNode.Name
		}
	}
}
Function Get-SqlServices {
	$Results = @()	
	$Sql_Services = (Get-WmiObject win32_service -ComputerName $env:computername | Where-Object {$_.Name -like 'MSSQL*' -or $_.Name -like 'SQLAgent$*' -or $_.Name -like 'SQLSERVERA*' -or $_.Name -like '*MsDts*' -or $_.Name -like '*MSOLAP*' -or $_.Name -like '*SSAS*' -or $_.Name -like '*ReportServer*' -or $_.Name -like '*DTC*'}) #testing
	Foreach($Sql in $Sql_Services) {
		$Results += New-Object -TypeName PSObject -Property @{
			ServiceName = $Sql.Name
			ShortName = Get-ShortName $Sql.Name
			ServiceType = Get-ServiceType $Sql.Name
			State = $Sql.State
			StartMode = $Sql.StartMode
			SvcAcc = $Sql.StartName
			InstanceId = Get-InstanceId $Sql.Name
			IsClustered = Get-IsClustered $Sql.Name
			IsHadr = Get-IsHadr $Sql.Name
			SqlClusterName = Get-ClusterSqlName $Sql.Name
			PreferredNode = Get-SqlPrefferedNode $Sql.Name
			CurrentNode = Get-SqlCurrentNode $Sql.Name
		}
	}
	$Results | Select-Object -Property ServiceName,ShortName,ServiceType,State,StartMode,SvcAcc,InstanceId,IsClustered,IsHadr,SqlClusterName,PreferredNode,CurrentNode
}

#Step03: Create report if requested
If($Report -in ('yes','y')){
	$Script_Dir = Split-Path -Parent $MyInvocation.MyCommand.Path
	$Date = (Get-Date).ToString('yyyyMMdd_hhmmss')
	$Filename = 'Report_'+$Date+'.txt'
	$Report = Join-Path -Path $Script_Dir -ChildPath $Filename
	$Header = 'Configuration of SQL Services on '+$env:computername+' on '+(Get-Date).ToString('yyyy/MM/dd "at" hh:mm:ss')
	Set-Content -Path $Report -Value $Header 
	Get-SqlServices | Out-File -FilePath $Report -Append -Force 
}

#Step04: Configure startup for SQL Standalones
$Services = Get-SqlServices | Where-Object { $_.ServiceType -in ('SqlInstance','SqlAgent') -and $_.Startup -ne 'Disabled' -and $_.IsClustered -ne 1 }
Foreach($Service in $Services){
	If($Service.StartMode -ne 'Automatic'){
		<#test_line#> Write-Host ("`tSet-Service '"+$Service.ServiceName+"' -StartupType Automatic -ErrorAction Stop")
		<#prod_line#> Set-Service $Service.ServiceName -StartupType Automatic -ErrorAction Stop
		If($SqlDelayed -in ('yes','y')){
			<#test_line#> Write-Host ("`tsc.exe config '"+$Service.ServiceName+"' start= delayed-auto | Out-Null")
			<#prod_line#> sc.exe config $Service.ServiceName start= delayed-auto | Out-Null
			<#test_line#> Write-Host ("`tsc.exe failure '"+$Service.ServiceName+"' reset= 60 actions= restart/5000 | Out-Null")
			<#prod_line#> sc.exe failure $Service.ServiceName reset= 60 actions= restart/5000 | Out-Null
		}
	}
	Elseif($Service.StartMode -eq 'Automatic'){
		<#test_line#> Write-Host ("`tService '"+$Service.ServiceName+"' is already configured to start atuomatically.")
	}
	Else{
		<#test_line#> Write-Host ("`tService '"+$Service.ServiceName+"' is disabled. No action taken.")
	}
}
#Step05: Configure startup for SQL Clustered
$Services = Get-SqlServices | Where-Object { ($_.ServiceType -eq 'SqlInstance' -or $_.ServiceType -eq 'SqlAgent') -and $_.Startup -ne 'Disabled' -and $_.IsClustered -eq 1 }
Foreach($Service in $Services){
	If($Service.StartMode -ne 'Manual'){
		<#test_line#> Write-Host ("`tSet-Service '"+$Service.ServiceName+"' -StartupType Manual -ErrorAction Stop")
		<#prod_line#> Set-Service $Service.ServiceName -StartupType Manual -ErrorAction Stop
	}
	Elseif($Service.StartMode -eq 'Manual'){
		<#test_line#> Write-Host ("`tService '"+$Service.ServiceName+"' is already configured to start manually.")
	}
	Else{
		<#test_line#> Write-Host ("`tService '"+$Service.ServiceName+"' is disabled. No action taken.")
	}
}
#Step06: Configure startup for SSIS/SSAS/SSRS
$Services = Get-SqlServices | Where-Object { $_.ServiceType -in ('SsasInstance','SsisInstance','SsrsInstance') -and $_.Startup -ne 'Disabled' }
Foreach($Service in $Services){
	If($Service.StartMode -ne 'Automatic'){
		<#test_line#> Write-Host ("`tSet-Service '"+$Service.ServiceName+"' -StartupType Automatic -ErrorAction Stop")
		<#prod_line#> Set-Service $Service.ServiceName -StartupType Automatic -ErrorAction Stop
	}
	Elseif($Service.StartMode -eq 'Automatic'){
		<#test_line#> Write-Host ("`tService '"+$Service.ServiceName+"' is already configured to start atuomatically.")
	}
	Else{
		<#test_line#> Write-Host ("`tService '"+$Service.ServiceName+"' is disabled. No action taken.")
	}
}
#Step07: Configure startup for CEIP
$Services = Get-SqlServices | Where-Object { $_.ServiceType -like '*Telemetry' }
Foreach($Service in $Services){
	If($Service.StartMode -ne 'Disabled'){
		If($_.State -eq 'Running'){
			<#test_line#> Write-Host ("`tStop-Service '"+$Service.ServiceName+"' -NoWait -Force -ErrorAction Stop")
			<#prod_line#> Stop-Service $Service.ServiceName -Force -ErrorAction Stop 
			Write-Host ("`t`tWaiting for service "+$Service.ServiceName+" to stop.")
				While((Get-SqlServices | Where-Object {$_.ServiceName -eq $Service.ServiceName}).State -ne 'Stopped'){
				}
			<#test_line#> Write-Host ("`tSet-Service '"+$Service.ServiceName+"' -StartupType Disabled -ErrorAction Stop")
			<#prod_line#> Set-Service $Service.ServiceName -StartupType Disabled -ErrorAction Stop
		}
		Else{
			<#test_line#> Write-Host ("`tSet-Service '"+$Service.ServiceName+"' -StartupType Disabled -ErrorAction Stop")
			<#prod_line#> Set-Service $Service.ServiceName -StartupType Disabled -ErrorAction Stop
		}
	}
	Else{
		<#test_line#> Write-Host ("`tService '"+$Service.ServiceName+"' is already disabled.")
	}
}
#Step08: Configure startup for SQL Browser
	$Sql_Instances = Get-SqlServices | Where-Object { $_.ServiceType -like 'SqlInstance' }
	$Browser_Service = Get-SqlServices | Where-Object { $_.ServiceType -like 'SqlBrowser' }
	#Count SQL instances
	$i = 0
	$j = 0
	$k = 0
	Foreach($Instance in $Sql_Instances){
		$i++
	}
	#Count SQL instances using static ports
	Foreach($Instance in $Sql_Instances){
		$Static_Port = (Get-ItemProperty -Path ("HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\"+$Instance.InstanceId+"\MSSQLServer\SuperSocketNetLib\Tcp\IPAll" )).TcpPort
		If(!$Static_Port -eq $false){
			$j++
		}
	}
	#Count clustered instances
	Foreach($Instance in $Sql_Instances){
		If($Instance.IsClustered -eq 1){
			$k++
		}
	}
	#Check if SQL Browser is needed
	If($j -lt $i){
		Write-Host "At least one instance is not using static port. SQL Browser is needed."
	}
	If($k -gt 0){
		Write-Host "At least one instance is a clustered instance. SQL Browser is recommended."
	}
	If($i -eq $j){
		Write-Host "All instances are using static port. SQL Browser is not needed."
	}
	If($EnabledBrowser -eq $null){
		$Conf = Read-Host "Should SQL Browser be set to Automatic startup? [yes/no] [y/n]"
	}
	If($Conf -in ('yes','y') -or $EnabledBrowser -in ('yes','y') ){
		If($Browser_Service.StartMode -ne 'Automatic'){
			<#test_line#> Write-Host ("`tSet-Service '"+$Service.ServiceName+"' -StartupType Automatic -ErrorAction Stop")
			<#prod_line#> Set-Service $Service.ServiceName -StartupType Automatic -ErrorAction Stop
		}
		Else{
			<#test_line#> Write-Host ("`tService '"+$Service.ServiceName+"' is already configured to start atuomatically.")
		}
	}
	Else{
		If($Browser_Service.StartMode -ne 'Disabled'){
			If($_.State -eq 'Running'){
				<#test_line#> Write-Host ("`tStop-Service '"+$Service.ServiceName+"' -NoWait -Force -ErrorAction Stop")
				<#prod_line#> Stop-Service $Service.ServiceName -Force -ErrorAction Stop 
				Write-Host ("`t`tWaiting for service "+$Service.ServiceName+" to stop.")
					While((Get-SqlServices | Where-Object {$_.ServiceName -eq $Service.ServiceName}).State -ne 'Stopped'){
					}
				<#test_line#> Write-Host ("`tSet-Service '"+$Service.ServiceName+"' -StartupType Disabled -ErrorAction Stop")
				<#prod_line#> Set-Service $Service.ServiceName -StartupType Disabled -ErrorAction Stop
			}
			Else{
				<#test_line#> Write-Host ("`tSet-Service '"+$Service.ServiceName+"' -StartupType Disabled -ErrorAction Stop")
				<#prod_line#> Set-Service $Service.ServiceName -StartupType Disabled -ErrorAction Stop
			}
		}
		Else{
			<#test_line#> Write-Host ("`tService '"+$Service.ServiceName+"' is already disabled.")
		}
	}

#Step09: Create final report
If($Report -in ('yes','y')){
	$Header = 'Configuration of SQL Services after changes.'
	Add-Content -Path $Report -Value $Header 
	Get-SqlServices | Out-File -FilePath $Report -Append -Force 
	Write-Host ("Report: "+$Report)
}
