Get-DtcTransactionsTraceSetting | Format-List -Property AbortedTransactionsTracingEnabled,AllTransactionsTracingEnabled,LongLivedTransactionsTracingEnabled
$Dtcs = (Get-Dtc | Select-Object -Property DtcName)
Foreach($Dtc in $Dtcs) {
    $DtcName = $Dtc.DtcName
    Write-Host "Configs of Dtc ["$DtcName.TrimStart()"]"
    $DtcPath = (Get-DtcLog).Path
    Write-Host "Log path: "$DtcPath
    $NetworkDtcAccess = If((Get-DtcAdvancedSetting -Name "NetworkDtcAccess" -Subkey "Security") -eq 1){"True"}Else{"False"}
    Write-Host "NetworkDtcAccess: "$NetworkDtcAccess
    Get-DtcNetworkSetting
}
