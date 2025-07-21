#Get-Right -Account MYDOMAIN\myaccount -Right 'Perform volume maintenance tasks'
#Get-Right -Account MYDOMAIN\myaccount -Right 'Lock pages in memory'
<# Created by Mateusz Wierzbowski
Creation date: 2022/07/22#>
Function Get-Right {
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

	secedit /export /cfg $Temp_Export /quiet

	$Line = (Select-String -Path $Temp_Export -Pattern $Permission).Line
	If($Line -notmatch $Sid){
		$Result = ("Account $Account do not have $Right")
	}
	Else{
		$Result = ("Account $Account already has $Right")
	}
	Remove-Item $Temp_Export -Force

	$Result
}
