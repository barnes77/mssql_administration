Function Grant-MpRights {
	Param (
		[Parameter(Mandatory=$true)][string]$Drive,
		[Parameter(Mandatory=$true)][string]$Identity,
		[Parameter(Mandatory=$true)][string]$Rights
	)
	$Acl = [io.directory]::GetAccessControl((Get-WmiObject Win32_Volume | Where-Object {$_.Name -eq $Drive}).DeviceId)
	If (!($Acl | Select-Object -ExpandProperty Access | Where-Object {$_.IdentityReference -like ('*'+$Identity+'*') -and $_.FileSystemRights -eq $Rights})){
		$AclRule = New-Object System.Security.AccessControl.FileSystemAccessRule($Identity,$Rights,'ContainerInherit, ObjectInherit','None','Allow')
		$Acl.SetAccessRule($AclRule) | Out-Null
		[io.directory]::SetAccessControl((Get-WmiObject Win32_Volume | Where-Object {$_.Name -eq $Drive}).DeviceId,$Acl)
		Write-Host `t'Modify over mount point '$Drive' was granted to'$Identity
	} Else {
		Write-Host `t$Identity 'already had Modify over' $Drive
	}
}
