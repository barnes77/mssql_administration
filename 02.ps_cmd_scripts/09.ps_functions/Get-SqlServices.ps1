<# Created by Mateusz Wierzbowski
Creation date: 2022/07/18-07/22
Main funtion: Get-SqlServices
Depedendent functions: Get-ShortName,Get-ServiceType,Get-InstanceId,Get-IsClustered,Get-IsHadr,Get-ClusterSqlName,Get-SqlPrefferedNode,Get-SqlCurrentNode,Test-RegistryValue #>
Function Test-RegistryValue { #source: www.jonathanmedd.net/2014/02/testing-for-the-presence-of-a-registry-key-and-value.html
	Param (
		[Parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()]$Path,
		[parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()]$Value
	)
	Try {
		Get-ItemProperty -Path $Path | Select-Object -ExpandProperty $Value -ErrorAction Stop | Out-Null
		Return $true
	}
	Catch {
		Return $false
	}
}
Function Get-ShortName {
	Param (
		[Parameter(Mandatory=$true)][string]$Service_Name
	)
	$Service_Name.Replace('MSSQL$','').Replace('SQLAgent$','').Replace('MSOLAP$','').Replace('MSSQLFDLauncher$','').Replace('ReportServer$','').Replace('SQLTELEMETRY$','').Replace('SSASTELEMETRY$','').Replace('SSRSTELEMETRY$','')
}
Function Get-ServiceType {
	Param (
		[Parameter(Mandatory=$true)][string]$Service_Name
	)
	If($Service_Name -like 'MSSQL$*' -or $Service_Name -eq 'MSSQLSERVER') {'SqlInstance'} 
		Elseif($Service_Name -like 'SQLAgent$*' -or $Service_Name -eq 'SQLSERVERAGENT') {'SqlAgent'} 
		Elseif($Service_Name -like 'MSOLAP$*') {'SsasInstance'} 
		Elseif($Service_Name -like '*MsDts*') {'SsisInstance'} 
		Elseif($Service_Name -like '*ReportServer*') {'SsrsInstance'} 
		Elseif($Service_Name -like '*FDLauncher*') {'FDLauncher'} 
		Elseif($Service_Name -eq 'SQLBrowser') {'SqlBrowser'} 
		Elseif($Service_Name -eq 'SQLWriter') {'SqlWriter'} 
		Elseif($Service_Name -like '*SQLTELEMETRY*') {'SqlTelemetry'} 
		Elseif($Service_Name -like '*SSASTELEMETRY*') {'SsasTelemetry'} 
		Elseif($Service_Name -like '*SSRSTELEMETRY*') {'SsrsTelemetry'} 
		Elseif($Service_Name -like '*DTC*') {'Dtc'} ##testing
		Else {'Other'}
}
Function Get-InstanceId {
	Param (
		[Parameter(Mandatory=$true)][string]$Service_Name
	)

	If((Get-ServiceType -Service_Name $Service_Name) -in ('SqlInstance','SqlAgent')) {
		$Instance_Name = Get-ShortName -Service_Name $Service_Name
		(Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL').$Instance_Name
	}
}
Function Get-IsClustered {
	Param (
		[Parameter(Mandatory=$true)][string]$Service_Name
	)

	If((Get-ServiceType -Service_Name $Service_Name) -in ('SqlInstance','SqlAgent')) {
		$Instance_Id = Get-InstanceId -Service_Name $Service_Name
		(Get-ItemProperty -Path ("HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\" + $Instance_Id + "\ClusterState")).SQL_Engine_Core_Inst
	}
	If((Get-ServiceType -Service_Name $Service_Name) -eq 'Dtc') { ##testing
		If((Test-RegistryValue -Path "HKLM:\Cluster\ResourceTypes\Distributed Transaction Coordinator" -Value ClusterDefaultVirtualServer) -eq $true){
			1
		}
	}
}
Function Get-IsHadr {
	Param (
		[Parameter(Mandatory=$true)][string]$Service_Name
	)

	If((Get-ServiceType -Service_Name $Service_Name) -eq 'SqlInstance') {
		$Instance_Id = Get-InstanceId -Service_Name $Service_Name
		If((Test-Path -Path ("HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\" + $Instance_Id + "\MSSQLServer\HADR")) -eq $true){
			(Get-ItemProperty -Path ("HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\" + $Instance_Id + "\MSSQLServer\HADR")).HADR_Enabled
		}
		Else {
			0
		}
	}
}
Function Get-ClusterSqlName {
	Param (
		[Parameter(Mandatory=$true)][string]$Service_Name
	)
	Try {
		If(!(Get-Module -name FailoverClusters)){Import-Module FailoverClusters -Force -ErrorAction Stop}
	}
	Catch {
		$Error_Message = $_.Exception
	}
	If((Get-IsClustered -Service_Name $Service_Name) -eq 1 -and (Get-ServiceType -Service_Name $Service_Name) -eq 'SqlInstance'){
		If($Error_Message -notlike '*specified module ''FailoverClusters'' was not loaded*'){
			$Instance_Id = Get-InstanceId -Service_Name $Service_Name
			(Get-ItemProperty -Path ("HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\" + $Instance_Id + "\Cluster")).ClusterName
		}
	}
	If((Get-IsClustered -Service_Name $Service_Name) -eq 1 -and (Get-ServiceType -Service_Name $Service_Name) -eq 'Dtc'){ ##testing
		If($Error_Message -notlike '*specified module ''FailoverClusters'' was not loaded*'){
			(Get-ItemProperty -Path "HKLM:\Cluster\ResourceTypes\Distributed Transaction Coordinator").ClusterDefaultVirtualServer
		}
	}
}
Function Get-SqlPrefferedNode {
	Param (
		[Parameter(Mandatory=$true)][string]$Service_Name
	)
	Try {
		If(!(Get-Module -name FailoverClusters)){Import-Module FailoverClusters -Force -ErrorAction Stop}
	}
	Catch {
		$Error_Message = $_.Exception
	}
	If((Get-IsClustered -Service_Name $Service_Name) -eq 1){
		If($Error_Message -notlike '*specified module ''FailoverClusters'' was not loaded*'){
			$Cluster_Sql_Name = Get-ClusterSqlName -Service_Name $Service_Name
			$Cluster_Role = (Get-ClusterResource | Where-Object { $_.Name -match $Cluster_Sql_Name -and $_.ResourceType -eq 'Network Name'}).OwnerGroup
			((Get-ClusterOwnerNode -Group $Cluster_Role | Select-Object -Property OwnerNodes).OwnerNodes | Where-Object {$_.State -eq "Up"} | Select-Object -Property Name -First 1).Name
			}
		}
}
Function Get-SqlCurrentNode {
	Param (
		[Parameter(Mandatory=$true)][string]$Service_Name
	)
	Try {
		If(!(Get-Module -name FailoverClusters)){Import-Module FailoverClusters -Force -ErrorAction Stop}
	}
	Catch {
		$Error_Message = $_.Exception
	}
	If((Get-IsClustered -Service_Name $Service_Name) -eq 1){
		If($Error_Message -notlike '*specified module ''FailoverClusters'' was not loaded*'){
			$Cluster_Sql_Name = Get-ClusterSqlName -Service_Name $Service_Name
			$Cluster_Role = (Get-ClusterResource | Where-Object { $_.Name -match $Cluster_Sql_Name -and $_.ResourceType -eq 'Network Name'}).OwnerGroup
			(Get-ClusterGroup | Where-Object {$_.Name -eq $Cluster_Role }).OwnerNode.Name
		}
	}
}
Function Get-SqlServices {
	$Results = @()	
	$Sql_Services = (Get-WmiObject win32_service -ComputerName $env:computername | Where-Object {$_.Name -like 'MSSQL*' -or $_.Name -like 'SQLAgent$*' -or $_.Name -like 'SQLSERVERA*' -or $_.Name -like '*MsDts*' -or $_.Name -like '*MSOLAP*' -or $_.Name -like '*SSAS*' -or $_.Name -like '*ReportServer*' -or $_.Name -like '*DTC*'}) #testing
	Foreach($Sql in $Sql_Services) {
		$Results += New-Object -TypeName PSObject -Property @{
			ServiceName = $Sql.Name
			ShortName = Get-ShortName $Sql.Name
			ServiceType = Get-ServiceType $Sql.Name
			State = $Sql.State
			StartMode = $Sql.StartMode
			SvcAcc = $Sql.StartName
			InstanceId = Get-InstanceId $Sql.Name
			IsClustered = Get-IsClustered $Sql.Name
			IsHadr = Get-IsHadr $Sql.Name
			SqlClusterName = Get-ClusterSqlName $Sql.Name
			PreferredNode = Get-SqlPrefferedNode $Sql.Name
			CurrentNode = Get-SqlCurrentNode $Sql.Name
		}
	}
	$Results | Select-Object -Property ServiceName,ShortName,ServiceType,State,StartMode,SvcAcc,InstanceId,IsClustered,IsHadr,SqlClusterName,PreferredNode,CurrentNode
}
Get-SqlServices | Out-GridView
