###Procedure how to set SqlIaasExtension on Azure VM from Lightweight to Full and to configure tempdb (e.g. on temporary storage in case of D-series machines)
#Actions are not needed if a machine with SQL Server was deployed as such from marketplace
 
###Variables (used to change them across all steps at once)
#VM: 							VM-test
#TempDbData:					E:\tempdb\Data
#TempDbLog:						E:\tempdb\Log
#TempDbPersistFolderPath		E:\tempdb
#SubscriptionID					aade92fd-a18a-423a-8dca-4ff6ee880879
 
###First step: verify current state of SqlIaaSExtension
Get-AzSubscription
Set-AzContext -Subscription 'aade92fd-a18a-423a-8dca-4ff6ee880879'
$Vm = Get-AzVM -Name 'VM-test'
$ResourceGroupName = $Vm.ResourceGroupName
$VmName = $Vm.Name
$VmLocation = $Vm.Location
$Extension = Get-AzVMExtension -ResourceGroupName $ResourceGroupName -VMName $VmName -Name "SqlIaasExtension"
$Extension
 
###Second step: this will upgrade SqlIaaSExtension to Full
#Enable Management of storage in SQL Server machine, wait for deployment
 
###Third step: add new string values in registry
#Path: HKLM:SOFTWARE\Microsoft\SqlIaaSExtension\CurrentVersion
#String: TempDbData						Value: E:\tempdb\Data
#String: TempDbLog						Value: E:\tempdb\Log
#String: TempDbPersistFolder			Value: true
#String: TempDbPersistFolderPath		Value: E:\tempdb
 
###Fourth step: include tempdb configuration in the SqlIaaSExtension via Azure PS
$NewSettings = @{
	"sqlServerConfiguration" = @{
		"storageConfigurationSettings" = @{
			"SQLWorkloadTypeUpdateSettings" = @{
				"SQLWorkloadType" = 2
			};
			"SQLTempDbSettings" = @{
				"DefaultFilePath" = "E:\tempdb"
				};
				"SQLSystemDbOnDataDisk" = $false
			}
		}
	"SqlManagement"= @{
		"IsEnabled"= $true
	}
	"LeastPrivilegeModeSettings"= @{
		"IsEnabled"= $true
	}
   }
 
Set-AzVMExtension -ResourceGroupName $ResourceGroupName -VMName $VmName -Location $location -Name $Extension.Name -Publisher $Extension.Publisher -ExtensionType $Extension.ExtensionType -TypeHandlerVersion $Extension.TypeHandlerVersion -Settings $NewSettings -ForceRerun $(New-Guid).Guid
 
####Fifth step: configure tempdb in SqlIaaSExtension
#Wait until tempdb is visible in Storage -> Management
#Go to Configure, next to "Manage tempdb database folders on restart" click "No" and wait for deployment to finish
#Go to Configure, next to "Manage tempdb database folders on restart" click "Yes", configure tempdb folder & files and wait for deployment to finish
#Restart SQL Server
