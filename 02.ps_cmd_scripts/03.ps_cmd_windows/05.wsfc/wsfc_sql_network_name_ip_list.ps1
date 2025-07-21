#script from TMKP
$Groups = Get-ClusterGroup | Where-Object {($_.Name -ne "Cluster Group") -and ($_.Name -ne "Available Storage")}
	$Object = foreach ($Group in $Groups) {
		$DnsName = $Group | Get-ClusterResource | Where-Object {$_.ResourceType -eq "Network Name"} | Get-ClusterParameter DnsName
		$IP = $Group | Get-ClusterResource | Where-Object {$_.ResourceType -eq "IP Address"} | Get-ClusterParameter Address
		New-Object -TypeName psobject -Property @{
			Group = $Group.Name
			DnsName = $DnsName.Value
			IP = $IP.Value
		}
	}
$Object | Select-Object Group, DnsName, IP
