#create FW rule for health probes from Load Balancer (by default 3 addresses: 1 for cluster, 2 for AOAGs)
	netsh advfirewall firewall add rule name="AzureLB_Probe" dir=in action=allow protocol=TCP localport=59997-59999 profile=any
 
#assign probe port to AOAG listener
	$ClusterNetworkName = "Cluster Network 2" #cluster network name
	$IPResourceName = "AoagListener_IpAddress" #name of cluster resource of AOAG listener
	$ListenerILBIP = "IpAddress" #IP address of AOAG listener
	[int]$ListenerProbePort = "59998" #probe port
 
	Import-Module FailoverClusters
 
	Get-ClusterResource $IPResourceName | 
		Set-ClusterParameter -Multiple @{"Address"="$ListenerILBIP";"ProbePort"=$ListenerProbePort;"SubnetMask"="255.255.255.224";"Network"="$ClusterNetworkName";"EnableDhcp"=0}
 
#assign probe port to cluster IP
	$ClusterNetworkName = "Cluster Network 2" #cluster network name
	$IPResourceName = "Cluster IP Address"  #name of cluster resource of cluster name
	$ClusterCoreIP = "IpAddress" #IP address of cluster resource of cluster name
	[int]$ClusterProbePort = "59999" #probe port
 
	Import-Module FailoverClusters
 
	Get-ClusterResource $IPResourceName | 
		Set-ClusterParameter -Multiple @{"Address"="$ClusterCoreIP";"ProbePort"=$ClusterProbePort;"SubnetMask"="255.255.255.224";"Network"="$ClusterNetworkName";"EnableDhcp"=0}
 
#get owner node of cluster name
	(Get-ClusterResource -Name 'Cluster Name').OwnerGroup.OwnerNode
 
#fail cluster name over to other node
	Move-ClusterGroup (Get-ClusterResource -Name 'Cluster Name').OwnerGroup -Node NodeNameHere
 
#dummy script for creating WSFC cluster in Azure on Windows 2019 without Distributed Server Name
#sqlha.com/configure-a-wsfc-in-azure-with-windows-server-2019-for-ags-and-fcis/
	New-Cluster -Name WSFCName -Node nodelist -StaticAddress IPAddress -NoStorage -AdministrativeAccessPoint DNS -ManagementPointNetworkType Singleton
 
#forced creation of quorum with Cloud Witness by using particular security protocol (in script TLS 1.2 is used)
#blog.sqlauthority.com/2019/01/04/sql-server-unable-to-set-cloud-witness-error-the-client-and-server-cannot-communicate-because-they-do-not-possess-a-common-algorithm/
	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
	Set-ClusterQuorum -Cluster "ClusterName" -CloudWitness -AccountName "AccountName" -AccessKey "AccessKey"
 
#forced creation of quorum in case of:
#NATIVE ERROR CODE : 1.
#WinRM cannot process the request. The following error with errorcode 0x80090322 occurred while using Kerberos authentication: An unknown security error occurred.
	$clus = Get-CimInstance -ClassName MSCluster_ClusterService -Namespace "root\mscluster"
	Invoke-CimMethod -InputObject $clus -MethodName "CreateCloudWitness" -Arguments @{AccountKey="XXXX"; AccountName = "YYYY"}
