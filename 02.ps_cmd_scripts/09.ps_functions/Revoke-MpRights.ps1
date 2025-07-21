Function Revoke-MpRights {
	Param (
		[Parameter(Mandatory=$true)][string]$Drive,
		[Parameter(Mandatory=$true)][string]$Identity
	)
	$Acl = [io.directory]::GetAccessControl((Get-WmiObject Win32_Volume | Where-Object {$_.Name -eq $Drive}).DeviceId)
	If ($Acl | Select-Object -ExpandProperty Access | Where-Object {$_.IdentityReference -like ('*'+$Identity+'*')}){
		$Acl.Access | Where-Object {$_.IdentityReference -eq $Identity} | ForEach-Object{$Acl.RemoveAccessRule($_)} | Out-Null
		[io.directory]::SetAccessControl((Get-WmiObject Win32_Volume | Where-Object {$_.Name -eq $Drive}).DeviceId,$Acl)
		Write-Host `t'Permissions of '$Identity' revoked from mount point'$Drive
	} Else {
		Write-Host `t$Identity' does not have permissions on mount point'$Drive
	}
}
