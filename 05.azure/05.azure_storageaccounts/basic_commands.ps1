#Get Storage Account
	Get-AzStorageAccount -ResourceGroupName MyRG -Name MySA
 
#Start Storage Account migration (change redundancy) via pipeline
	Get-AzStorageAccount -ResourceGroupName MyRG -Name MySA | Start-AzStorageAccountMigration  -TargetSku Standard_LRS -AsJob
 
#Start Storage Account migration (change redundancy)
	Start-AzStorageAccountMigration -AccountName MySA -ResourceGroupName MyRG -TargetSku Standard_LRS -Name JobNameHere -AsJob
