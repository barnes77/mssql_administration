$DtcDrive = (Get-ClusterResource | Where-Object {$_.ResourceType -eq "Physical Disk" -and $_.Name -like '*1_F*'} | ForEach-Object {
	$ResourceName = $_.Name
	$Resource = Get-WmiObject MSCluster_Resource -Namespace root/mscluster | Where-Object { $_.Name -eq $ResourceName }
	$Disk = Get-WmiObject -Namespace root/mscluster -Query "ASSOCIATORS OF {$Resource} WHERE ResultClass=MSCluster_Disk"
	$Partition = Get-WmiObject -Namespace root/mscluster -Query "ASSOCIATORS OF {$Disk} WHERE ResultClass=MSCluster_DiskPartition"
	$Partition
})
$DtcDrive = $DtcDrive.Path
$Dtc = (Get-Dtc | Where-Object {$_.DtcName -ne 'Local'}).DtcName
 
If((Get-DtcTransactionsTraceSetting).AllTransactionsTracingEnabled -eq $true){
	'AllTransactionsTracingEnabled setting is ok.'
}Else{
	'Setting AllTransactionsTracingEnabled to TRUE.'
	Set-DtcTransactionsTraceSetting -AllTransactionsTracingEnabled $true
}
 
If((Get-DtcLog -DtcName $Dtc).Path -like "$DtcDrive*"){
	'DTC log path is ok.'
}Else{
	'DTC log path is NOK!. Change it manually.'
}
 
If(!(Get-DtcAdvancedSetting -DtcName $Dtc -Name "NetworkDtcAccess" -Subkey "Security" -ErrorAction SilentlyContinue)){
	'Enabling Network DTC Access.'
	Set-DtcAdvancedSetting -DtcName $Dtc -Name "NetworkDtcAccess" -Subkey "Security" -Type "DWORD" -Value "1"
}Elseif((Get-DtcAdvancedSetting -DtcName $Dtc -Name "NetworkDtcAccess" -Subkey "Security") -ne 1){
	'Enabling Network DTC Access.'
	Set-DtcAdvancedSetting -DtcName $Dtc -Name "NetworkDtcAccess" -Subkey "Security" -Type "DWORD" -Value "1"
}
Else{
	Write-Host `t'Network DTC Access is ok.'
}
 
If((Get-DtcNetworkSetting -DtcName $Dtc).AuthenticationLevel -eq 'NoAuth'){
	'AuthenticationLevel setting is ok.'
}Else{
	'Setting AuthenticationLevel to TRUE.'
	Set-DtcNetworkSetting -DtcName $Dtc -AuthenticationLevel 'NoAuth' -Confirm:$false
}
 
If((Get-DtcNetworkSetting -DtcName $Dtc).RemoteClientAccessEnabled -eq $true){
	'RemoteClientAccessEnabled setting is ok.'
}Else{
	'Setting RemoteClientAccessEnabled to TRUE.'
	Set-DtcNetworkSetting -DtcName $Dtc -RemoteClientAccessEnabled $True -Confirm:$false
}
 
If((Get-DtcNetworkSetting -DtcName $Dtc).RemoteAdministrationAccessEnabled -eq $true){
	'RemoteAdministrationAccessEnabled setting is ok.'
}Else{
	'Setting RemoteAdministrationAccessEnabled to TRUE.'
	Set-DtcNetworkSetting -DtcName $Dtc -RemoteAdministrationAccessEnabled $True -Confirm:$false
}
 
If((Get-DtcNetworkSetting -DtcName $Dtc).InboundTransactionsEnabled -eq $true){
	'InboundTransactionsEnabled setting is ok.'
}Else{
	'Setting InboundTransactionsEnabled to TRUE.'
	Set-DtcNetworkSetting -DtcName $Dtc -InboundTransactionsEnabled $True -Confirm:$false
}
 
If((Get-DtcNetworkSetting -DtcName $Dtc).OutboundTransactionsEnabled -eq $true){
	'OutboundTransactionsEnabled setting is ok.'
}Else{
	'Setting OutboundTransactionsEnabled to TRUE.'
	Set-DtcNetworkSetting -DtcName $Dtc -OutboundTransactionsEnabled $True -Confirm:$false
}
 
If((Get-DtcNetworkSetting -DtcName $Dtc).XATransactionsEnabled -eq $true){
	'XATransactionsEnabled setting is ok.'
}Else{
	'Setting XATransactionsEnabled to TRUE.'
	Set-DtcNetworkSetting -DtcName $Dtc -XATransactionsEnabled $True -Confirm:$false
}
 
If((Get-DtcNetworkSetting -DtcName $Dtc).LUTransactionsEnabled -eq $true){
	'LUTransactionsEnabled setting is ok.'
}Else{
	'Setting LUTransactionsEnabled to TRUE.'
	Set-DtcNetworkSetting -DtcName $Dtc -LUTransactionsEnabled $True -Confirm:$false
}
 
Stop-Dtc -Confirm:$false
Start-Dtc
