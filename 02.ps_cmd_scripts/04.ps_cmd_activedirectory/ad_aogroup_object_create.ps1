$Ou = 'OUPathHere' 
$AoName = 'AOGroupNameHere'
$Domain = 'DomainNameHere'
$Cluster = 'ClusterNameHere'
 
$SamName = $AoName+'$'
$DnsName = $AoName+'.'+$Domain
$ClusterName = $Cluster+'$'
$AclPath = 'AD:\CN='+$AoName+','+$Ou
 
New-AdComputer -Name $AoName -SamAccountName $SamName -DNSHostName $DnsName -Enabled $true -Path $Ou
$Acl = Get-Acl -Path $AclPath
$Sid = [System.Security.Principal.IdentityReference] (Get-AdComputer -Identity $ClusterName).SID
$AdRights = [System.DirectoryServices.ActiveDirectoryRights] "GenericAll"
$Type = [System.Security.AccessControl.AccessControlType] "Allow"
$Acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $Sid,$AdRights,$Type))
$Acl | Set-Acl -Path $AclPath
