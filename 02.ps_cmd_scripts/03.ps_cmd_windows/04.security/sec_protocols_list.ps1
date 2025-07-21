<# Created by Mateusz Wierzbowski
Creation date v1.0: 2021/06/07
Creation date v2.0: 2022/12/05
Aim: Query registry to find security protocols enabled on the host #>
 
Get-ChildItem 'HKLM:SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols' -Recurse | Get-ItemProperty -Name Enabled -ErrorAction SilentlyContinue |
	Select-Object -Property Enabled,@{Name='Side';Expression={$_.PSChildName}},@{Name='Protocol';Expression={$_.PSParentPath.Replace("Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\","")}} |
	Sort-Object Protocol,Side | Format-Table Protocol,Side,Enabled -AutoSize
