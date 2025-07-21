Function Grant-NtfsRights {
	Param (
		[Parameter(Mandatory=$true)][string]$Drive,
		[Parameter(Mandatory=$true)][string]$Identity,
		[Parameter(Mandatory=$true)][string]$Rights
	)
	$Acl = Get-Acl -Path $Drive
	If (!($Acl | Select-Object -ExpandProperty Access | Where-Object {$_.IdentityReference -like ('*'+$Identity+'*') -and $_.FileSystemRights -eq $Rights})){
		$AclRule = New-Object System.Security.AccessControl.FileSystemAccessRule($Identity,$Rights,'ContainerInherit, ObjectInherit','None','Allow')
		$Acl.SetAccessRule($AclRule) | Out-Null
		Set-Acl -Path $Drive -AclObject $Acl
		Write-Host `t'Modify over '$Drive' was granted to'$Identity
	} Else {
		Write-Host `t$Identity 'already had Modify over'$Drive
	}
}
