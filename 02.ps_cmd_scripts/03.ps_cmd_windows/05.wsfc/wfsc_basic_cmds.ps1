#On node-level get list of accounts that are granted access to cluster 
	Get-ClusterAccess | Sort-Object IdentityReference
 
#Grant particular use a full access to cluster
	Grant-ClusterAccess -User "NT SERVICE\MSSQLSERVER" -Full
 
#Revoke any access to cluster from particular user
	Remove-ClusterAccess -User "NT SERVICE\MSSQLSERVER"
