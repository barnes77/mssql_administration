$Ou = 'OUPathHere' 
$SqlRoleName = 'AOGroupNameHere'
$Domain = 'DomainNameHere'
$Cluster = 'ClusterNameHere'
 
$ShortDomain = $Domain.Substring(0,$Domain.IndexOf('.'))
$SamName = $SqlRoleName+'$'
$DnsName = $SqlRoleName+'.'+$Domain
$ClusterName = $Cluster+'$'
$AclPath = 'AD:\CN='+$SqlRoleName+','+$Ou
 
$Spn01 = 'setspn -s MSServerClusterMgmtAPI/'+$SqlRoleName+'.'+$Domain+' '+$ShortDomain+'\'+$SqlRoleName+'$'
$Spn02 = 'setspn -s MSServerClusterMgmtAPI/'+$SqlRoleName+' '+$ShortDomain+'\'+$SqlRoleName+'$'
$Spn03 = 'setspn -s MSClusterVirtualServer/'+$SqlRoleName+'.'+$Domain+' '+$ShortDomain+'\'+$SqlRoleName+'$'
$Spn04 = 'setspn -s MSClusterVirtualServer/'+$SqlRoleName+' '+$ShortDomain+'\'+$SqlRoleName+'$'
$Spn05 = 'setspn -s HOST/'+$SqlRoleName+'.'+$Domain+' '+$ShortDomain+'\'+$SqlRoleName+'$'
$Spn06 = 'setspn -s HOST/'+$SqlRoleName+' '+$ShortDomain+'\'+$SqlRoleName+'$'
 
New-AdComputer -Name $SqlRoleName -SamAccountName $SamName -DNSHostName $DnsName -Enabled $true -Path $Ou
$Acl = Get-Acl -Path $AclPath
$Sid = [System.Security.Principal.IdentityReference] (Get-AdComputer -Identity $ClusterName).SID
$AdRights = [System.DirectoryServices.ActiveDirectoryRights] "GenericAll"
$Type = [System.Security.AccessControl.AccessControlType] "Allow"
$Acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $Sid,$AdRights,$Type))
$Acl | Set-Acl -Path $AclPath
 
cmd.exe /c $Spn01
cmd.exe /c $Spn02
cmd.exe /c $Spn03
cmd.exe /c $Spn04
cmd.exe /c $Spn05
cmd.exe /c $Spn06
