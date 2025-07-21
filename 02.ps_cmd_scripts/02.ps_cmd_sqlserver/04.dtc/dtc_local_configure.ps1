If((Get-DtcTransactionsTraceSetting).AllTransactionsTracingEnabled -eq $true){
	'AllTransactionsTracingEnabled setting is ok.'
}Else{
	'Setting AllTransactionsTracingEnabled to TRUE.'
	Set-DtcTransactionsTraceSetting -AllTransactionsTracingEnabled $true
}
 
If((Get-DtcLog -DtcName "Local").Path -eq 'C:\windows\system32\MSDtc'){
	'DTC log path is ok.'
}Else{
	'Configuring DTC log path.'
	Set-DtcLog -DtcName "Local" -Path 'C:\windows\system32\MSDtc' -Confirm:$false
}
 
If((Get-DtcAdvancedSetting -DtcName "Local" -Name "NetworkDtcAccess" -Subkey "Security") -ne 0){
	'Network DTC Access is ok.'
}Else{
	'Enabling Network DTC Access.'
	Set-DtcAdvancedSetting -DtcName "Local" -Name "NetworkDtcAccess" -Subkey "Security" -Type "DWORD" -Value "1"
}
 
If((Get-DtcNetworkSetting -DtcName "Local").AuthenticationLevel -eq 'NoAuth'){
	'AuthenticationLevel setting is ok.'
}Else{
	'Setting AuthenticationLevel to TRUE.'
	Set-DtcNetworkSetting -DtcName "Local" -AuthenticationLevel 'NoAuth' -Confirm:$false
}
 
If((Get-DtcNetworkSetting -DtcName "Local").RemoteClientAccessEnabled -eq $true){
	'RemoteClientAccessEnabled setting is ok.'
}Else{
	'Setting RemoteClientAccessEnabled to TRUE.'
	Set-DtcNetworkSetting -DtcName "Local" -RemoteClientAccessEnabled $True -Confirm:$false
}
 
If((Get-DtcNetworkSetting -DtcName "Local").RemoteAdministrationAccessEnabled -eq $true){
	'RemoteAdministrationAccessEnabled setting is ok.'
}Else{
	'Setting RemoteAdministrationAccessEnabled to TRUE.'
	Set-DtcNetworkSetting -DtcName "Local" -RemoteAdministrationAccessEnabled $True -Confirm:$false
}
 
If((Get-DtcNetworkSetting -DtcName "Local").InboundTransactionsEnabled -eq $true){
	'InboundTransactionsEnabled setting is ok.'
}Else{
	'Setting InboundTransactionsEnabled to TRUE.'
	Set-DtcNetworkSetting -DtcName "Local" -InboundTransactionsEnabled $True -Confirm:$false
}
 
If((Get-DtcNetworkSetting -DtcName "Local").OutboundTransactionsEnabled -eq $true){
	'OutboundTransactionsEnabled setting is ok.'
}Else{
	'Setting OutboundTransactionsEnabled to TRUE.'
	Set-DtcNetworkSetting -DtcName "Local" -OutboundTransactionsEnabled $True -Confirm:$false
}
 
If((Get-DtcNetworkSetting -DtcName "Local").XATransactionsEnabled -eq $true){
	'XATransactionsEnabled setting is ok.'
}Else{
	'Setting XATransactionsEnabled to TRUE.'
	Set-DtcNetworkSetting -DtcName "Local" -XATransactionsEnabled $True -Confirm:$false
}
 
If((Get-DtcNetworkSetting -DtcName "Local").LUTransactionsEnabled -eq $true){
	'LUTransactionsEnabled setting is ok.'
}Else{
	'Setting LUTransactionsEnabled to TRUE.'
	Set-DtcNetworkSetting -DtcName "Local" -LUTransactionsEnabled $True -Confirm:$false
}
 
Stop-Dtc -Confirm:$false
Start-Dtc
