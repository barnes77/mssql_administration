#Based on posts:
#stackoverflow.com/a/20803883
#stackoverflow.com/questions/6508874/powershell-com-settings
#social.technet.microsoft.com/Forums/en-US/fd339448-8430-4a60-9377-71fd8aae228d/comdtc-setup-with-powershell?forum=winserverpowershell
##PAY ATTENTION TO PORTS RANGE - after implementation test connection to Domain Controller via cmd: nltest /sc-query:%domain%
 
$ComAdmin = New-Object -com ("COMAdmin.COMAdminCatalog.1")
$LocalColl = $comAdmin.Connect("localhost")
$LocalComputer = $LocalColl.GetCollection("LocalComputer",$LocalColl.Name)
$LocalComputer.Populate()
$LocalComputerItem = $LocalComputer.Item(0)
 
If($LocalComputerItem.Value("TransactionTimeout") -ne 3600){Write-Host `t"Setting Transaction Timeout to 3600"
	$LocalComputerItem.Value("TransactionTimeout") = 3600
	$LocalComputer.SaveChanges() | Out-Null}
Else{Write-Host `t"Transaction Timeout is already set to 3600"}
 
If($LocalComputerItem.Value("DCOMEnabled") -ne $true){Write-Host `t"Enabling DCOM"
	$LocalComputerItem.Value("DCOMEnabled") = $true
	$LocalComputer.SaveChanges() | Out-Null}
Else{Write-Host `t"DCOM is already enabled"}
 
If($LocalComputerItem.Value("CISEnabled") -ne $true){Write-Host `t"Enabling COM Internet Services"
	$LocalComputerItem.Value("CISEnabled") = $true
	$LocalComputer.SaveChanges() | Out-Null}
Else{Write-Host `t"COM Internet Services are already enabled"}
 
If($LocalComputerItem.Value("Ports") -ne '1024-1123'){Write-Host `t"Changing Ports range"
	$LocalComputerItem.Value("Ports") = '1024-1123'
	
	Write-Host `t"Setting default type of port to Internet"
	$LocalComputerItem.Value("DefaultToInternetPorts") = $true
 
	Write-Host `t"Setting Ports to be used for Internet"
	$LocalComputerItem.Value("InternetPortsListed") = $true
 
	$LocalComputer.SaveChanges() | Out-Null}
Else{Write-Host `t"Ports range is already set as by default"}
 
Write-Host 'Configuration of DCOM was checked / done.'
Write-Host '!!!Configuration will take effect only after OS reboot.!!!'
