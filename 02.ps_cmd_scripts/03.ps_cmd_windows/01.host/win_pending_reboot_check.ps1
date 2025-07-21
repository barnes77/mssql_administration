#Other reasons for pending reboot are possible
$Test01 = Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -ErrorAction Ignore
$Test02 = Get-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -ErrorAction Ignore
$Test03 = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name PendingFileRenameOperations -ErrorAction Ignore
$Test04 = Invoke-WmiMethod -Namespace "ROOT\ccm\ClientSDK" -Class CCM_ClientUtilities -Name DetermineIfRebootPending -ErrorAction Ignore | Select-Object -ExpandProperty RebootPending
 
If(($Test01 -eq $true) -or ($Test02 -eq $true) -or ($Test03 -eq $true) -or ($Test04 -eq $true)){
	Write-Host "Pending reboot."
}
Else{
	Write-Host "No pending reboot."
}
