#.\sql_svc_rights.ps1
<# Created by Mateusz Wierzbowski
Creation date: 2022/07/22
Aim: Add [Perform Volume Management] and [Lock Pages in Memory] rights to all SQL Service Accounts on Windows Server  #>
 
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
 
Function Grant-Right {
	Param (
		[Parameter(Mandatory=$true)][string]$Account,
		[Parameter(Mandatory=$true)][string]$Right
	)
	$Rights_Array = @(
		[pscustomobject]@{FullName='Access Credential Manager as a trusted caller';ShortName='SeTrustedCredManAccessPrivilege'}
		[pscustomobject]@{FullName='Access this computer from the network';ShortName='SeNetworkLogonRight'}
		[pscustomobject]@{FullName='Act as part of the operating system';ShortName='SeTcbPrivilege'}
		[pscustomobject]@{FullName='Add workstations to domain';ShortName='SeMachineAccountPrivilege'}
		[pscustomobject]@{FullName='Adjust memory quotas for a process';ShortName='SeIncreaseQuotaPrivilege'}
		[pscustomobject]@{FullName='Allow log on locally';ShortName='SeInteractiveLogonRight'}
		[pscustomobject]@{FullName='Allow log on through Remote Desktop Services';ShortName='SeRemoteInteractiveLogonRight'}
		[pscustomobject]@{FullName='Back up files and directories';ShortName='SeBackupPrivilege'}
		[pscustomobject]@{FullName='Bypass traverse checking';ShortName='SeChangeNotifyPrivilege'}
		[pscustomobject]@{FullName='Change the system time';ShortName='SeSystemtimePrivilege'}
		[pscustomobject]@{FullName='Change the time zone';ShortName='SeTimeZonePrivilege'}
		[pscustomobject]@{FullName='Create a pagefile';ShortName='SeCreatePagefilePrivilege'}
		[pscustomobject]@{FullName='Create a token object';ShortName='SeCreateTokenPrivilege'}
		[pscustomobject]@{FullName='Create global objects';ShortName='SeCreateGlobalPrivilege'}
		[pscustomobject]@{FullName='Create permanent shared objects';ShortName='SeCreatePermanentPrivilege'}
		[pscustomobject]@{FullName='Create symbolic links';ShortName='SeCreateSymbolicLinkPrivilege'}
		[pscustomobject]@{FullName='Debug programs';ShortName='SeDebugPrivilege'}
		[pscustomobject]@{FullName='Deny access to this computer from the network';ShortName='SeDenyNetworkLogonRight'}
		[pscustomobject]@{FullName='Deny log on as a batch job';ShortName='SeDenyBatchLogonRight'}
		[pscustomobject]@{FullName='Deny log on as a service';ShortName='SeDenyServiceLogonRight'}
		[pscustomobject]@{FullName='Deny log on locally';ShortName='SeDenyInteractiveLogonRight'}
		[pscustomobject]@{FullName='Deny log on through Remote Desktop Services';ShortName='SeDenyRemoteInteractiveLogonRight'}
		[pscustomobject]@{FullName='Enable computer and user accounts to be trusted for delegation';ShortName='SeEnableDelegationPrivilege'}
		[pscustomobject]@{FullName='Force shutdown from a remote system';ShortName='SeRemoteShutdownPrivilege'}
		[pscustomobject]@{FullName='Generate security audits';ShortName='SeAuditPrivilege'}
		[pscustomobject]@{FullName='Impersonate a client after authentication';ShortName='SeImpersonatePrivilege'}
		[pscustomobject]@{FullName='Increase a process working set';ShortName='SeIncreaseWorkingSetPrivilege'}
		[pscustomobject]@{FullName='Increase scheduling priority';ShortName='SeIncreaseBasePriorityPrivilege'}
		[pscustomobject]@{FullName='Load and unload device drivers';ShortName='SeLoadDriverPrivilege'}
		[pscustomobject]@{FullName='Lock pages in memory';ShortName='SeLockMemoryPrivilege'}
		[pscustomobject]@{FullName='Log on as a batch job';ShortName='SeBatchLogonRight'}
		[pscustomobject]@{FullName='Log on as a service';ShortName='SeServiceLogonRight'}
		[pscustomobject]@{FullName='Manage auditing and security log';ShortName='SeSecurityPrivilege'}
		[pscustomobject]@{FullName='Modify an object label';ShortName='SeRelabelPrivilege'}
		[pscustomobject]@{FullName='Modify firmware environment values';ShortName='SeSystemEnvironmentPrivilege'}
		[pscustomobject]@{FullName='Obtain an impersonation token for another user in the same session';ShortName='SeDelegateSessionUserImpersonatePrivilege'}
		[pscustomobject]@{FullName='Perform volume maintenance tasks';ShortName='SeManageVolumePrivilege'}
		[pscustomobject]@{FullName='Profile single process';ShortName='SeProfileSingleProcessPrivilege'}
		[pscustomobject]@{FullName='Profile system performance';ShortName='SeSystemProfilePrivilege'}
		[pscustomobject]@{FullName='Remove computer from docking station';ShortName='SeUndockPrivilege'}
		[pscustomobject]@{FullName='Replace a process level token';ShortName='SeAssignPrimaryTokenPrivilege'}
		[pscustomobject]@{FullName='Restore files and directories';ShortName='SeRestorePrivilege'}
		[pscustomobject]@{FullName='Shut down the system';ShortName='SeShutdownPrivilege'}
		[pscustomobject]@{FullName='Synchronize directory service data';ShortName='SeSyncAgentPrivilege'}
		[pscustomobject]@{FullName='Take ownership of files or other objects';ShortName='SeTakeOwnershipPrivilege'}
	)

	If($Right -notin $Rights_Array.FullName) {
		Throw ($Right+" is not known.")
	}
	$Sec_Db = 'C:\Windows\security\database\secedit.sdb'
	If((Test-Path -Path $Sec_Db) -eq $false) {
		Throw ($Sec_Db+" was not found.")
	}


	$Domain = $Account.Substring(0,$Account.IndexOf('\'))
	$Acc_Name = $Account.Substring($Account.IndexOf('\')+1,$Account.Length-$Account.IndexOf('\')-1)
	$Permission = $Rights_Array | Where-Object { $_.FullName -eq $Right } 
	$Permission = $Permission.ShortName
	$Sid = ((New-Object System.Security.Principal.NTAccount($Domain,$Acc_Name)).Translate([System.Security.Principal.SecurityIdentifier])).Value
	$Temp_Path = [System.IO.Path]::GetTempPath()
	$Date = (Get-Date).ToString('yyyyMMdd_hhmmss')
	$Temp_Export = Join-Path $Temp_Path -ChildPath "export$Date.inf"
	$Temp_Sec_Db = Join-Path $Temp_Path -ChildPath "secedit$Date.sdb"
	$Temp_Import = Join-Path $Temp_Path -ChildPath "import$Date.inf"
	Foreach($Line in @("[Unicode]","Unicode=yes","[System Access]","[Event Audit]","[Registry Values]","[Version]","signature=""`$CHICAGO`$""","Revision=1","[Profile Description]","Description=Configure right ""$FullName"" via Grant-Right on $Date","[Privilege Rights]")) {
		Add-Content -Path $Temp_Import -Value $Line
	}

	secedit /export /cfg $Temp_Export /quiet

	$Line = (Select-String -Path $Temp_Export -Pattern $Permission).Line
	If($Line -notmatch $Sid){
		$NewLine = -join ($Line,",*",$Sid)
		Add-Content -Path $Temp_Import -Value $NewLine
		
		secedit /import /db $Temp_Sec_Db /cfg $Temp_Import /quiet
		secedit /configure /db $Temp_Sec_Db /quiet
		
		Remove-Item $Temp_Sec_Db -Force
		$Result = ("Account $Account was granted with $Right")
	}
	Else{
		$Result = ("Account $Account already has $Right")
	}
	Remove-Item $Temp_Export -Force
	Remove-Item $Temp_Import -Force

	$Result
}


$Sql_Services = Get-SqlServices 
Foreach($Service in $Sql_Services) {
	If($Service.ServiceType -eq 'SqlInstance'){
		Try {
			Grant-Right -Account $Service.SvcAcc -Right 'Perform volume maintenance tasks'
			Grant-Right -Account $Service.SvcAcc -Right 'Lock pages in memory'
		}
		Catch{
			$Error_Message = $_.Exception
			$Error_Message
		}
	}
}
