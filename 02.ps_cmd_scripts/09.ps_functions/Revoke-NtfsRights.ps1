Function Revoke-NtfsRights {
	Param (
		[Parameter(Mandatory=$true)][string]$Drive,
		[Parameter(Mandatory=$true)][string]$Identity
	)
	$Acl = Get-Acl -Path $Drive
	If ($Acl | Select-Object -ExpandProperty Access | Where-Object {$_.IdentityReference -like ('*'+$Identity+'*')}){
		$Acl.Access | Where-Object {$_.IdentityReference -eq $Identity} | ForEach-Object{$Acl.RemoveAccessRule($_)} | Out-Null
		Set-ACL -Path $Drive -ACLObject $Acl
		Write-Host `t'Permissions of '$Identity' revoked from'$Drive
	} Else {
		Write-Host `t$Identity' does not have permissions on'$Drive
	}
 
}
