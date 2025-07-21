#Revoke-Right -Account MYDOMAIN\myaccount -Right 'Perform volume maintenance tasks'
#Revoke-Right -Account MYDOMAIN\myaccount -Right 'Lock pages in memory'
<# Created by Mateusz Wierzbowski
Creation date: 2022/07/22#>
Function Revoke-Right {
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
	$Sid_Short = -join ('*',$Sid)
	$Sid_Full = -join (',*',$Sid)
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
		$Result = ("Account $Account do not have $Right")
	}
	Elseif($Line -match $Sid_Full){
		$NewLine = $Line.Replace($Sid_Full,'')
		Add-Content -Path $Temp_Import -Value $NewLine
		
		secedit /import /db $Temp_Sec_Db /cfg $Temp_Import /quiet
		secedit /configure /db $Temp_Sec_Db /quiet
		
		Remove-Item $Temp_Sec_Db -Force
		$Result = ("Account $Account had $Right revoked.")
	}
	Elseif($Line -match $Sid_Short){
		$NewLine = $Line.Replace($Sid_Short,'')
		Add-Content -Path $Temp_Import -Value $NewLine
		
		secedit /import /db $Temp_Sec_Db /cfg $Temp_Import /quiet
		secedit /configure /db $Temp_Sec_Db /quiet
		
		Remove-Item $Temp_Sec_Db -Force
		$Result = ("Account $Account had $Right revoked.")
	}
	Remove-Item $Temp_Export -Force
	Remove-Item $Temp_Import -Force

	$Result
}
