#Test connectivity to specific port with PS
	Test-NetConnection -TargetName ServerName -Port PortNumber
 
#Test connectivity to specific port with telnet
	telnet ServerName PortNumber
 
#Test connectivity to common port with PS
	Test-NetConnection -TargetName ServerName -CommonTCPPort RDP
 
#Test connectivity buffer with PS
	Test-Connection -ComputerName ServerName -BufferSize 1 -Count 100
 
#Check process owning particular port
	Get-Process -Id (Get-NetTCPConnection -LocalPort portNumber).OwningProcess 
 
#Check processes owning local ports with PS
	Get-NetTCPConnection | Where-Object {$_.LocalAddress -notlike "::" -and $_.LocalAddress -notlike "0.0.0.0" -and $_.LocalAddress -notlike "127.0.0.1" }  | Sort-Object {$_.LocalPort} | 
		Select-Object -Property LocalAddress, LocalPort, @{Name='Process';Expression={Get-Process -Id (Get-NetTCPConnection -LocalPort 139).OwningProcess|Select-Object -Expand ProcessName}} , State, RemoteAddress, RemotePort |
		Out-GridView 
 
#Check processes listening with cmd
	netstat -a | find /I "LISTEN"
 
#Install telnet
	Install-WindowsFeature -Name Telnet-Client
