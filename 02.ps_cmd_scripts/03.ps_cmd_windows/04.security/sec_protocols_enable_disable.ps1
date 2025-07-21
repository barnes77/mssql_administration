$Reg = 'HKLM:SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols'
$RegExport = 'C:\temp\protocols_reg_backup.reg'
Invoke-Command {reg export $Reg.Replace('HKLM:','HKLM\') $RegExport /y} | Out-Null
 
#disable SSL 2.0
$Protocol = 'SSL 2.0'
$RegPath = $Reg+'\'+$Protocol
$RegPathSrv = $Reg+'\'+$Protocol+'\Server'
$RegPathCl = $Reg+'\'+$Protocol+'\Client'
New-Item -Path $Reg -Name $Protocol -Force | Out-Null
New-Item -Path $RegPath -Name 'Server' -Force | Out-Null
#New-Item -Path $RegPath -Name 'Client' -Force | Out-Null
New-ItemProperty -Path $RegPathSrv -Name 'Enabled' -Value 0 -PropertyType DWORD -Force | Out-Null
#New-ItemProperty -Path $RegPathCl -Name 'Enabled' -Value 0 -PropertyType DWORD -Force | Out-Null
 
#disable SSL 3.0
$Protocol = 'SSL 3.0'
$RegPath = $Reg+'\'+$Protocol
$RegPathSrv = $Reg+'\'+$Protocol+'\Server'
$RegPathCl = $Reg+'\'+$Protocol+'\Client'
New-Item -Path $Reg -Name $Protocol -Force | Out-Null
New-Item -Path $RegPath -Name 'Server' -Force | Out-Null
New-Item -Path $RegPath -Name 'Client' -Force | Out-Null
New-ItemProperty -Path $RegPathSrv -Name 'Enabled' -Value 0 -PropertyType DWORD -Force | Out-Null
New-ItemProperty -Path $RegPathCl -Name 'Enabled' -Value 0 -PropertyType DWORD -Force | Out-Null
 
#disable TLS 1.0
$Protocol = 'TLS 1.0'
$RegPath = $Reg+'\'+$Protocol
$RegPathSrv = $Reg+'\'+$Protocol+'\Server'
$RegPathCl = $Reg+'\'+$Protocol+'\Client'
New-Item -Path $Reg -Name $Protocol -Force | Out-Null
New-Item -Path $RegPath -Name 'Server' -Force | Out-Null
New-Item -Path $RegPath -Name 'Client' -Force | Out-Null
New-ItemProperty -Path $RegPathSrv -Name 'Enabled' -Value 0 -PropertyType DWORD -Force | Out-Null
New-ItemProperty -Path $RegPathCl -Name 'Enabled' -Value 0 -PropertyType DWORD -Force | Out-Null
 
#disable TLS 1.1
$Protocol = 'TLS 1.1'
$RegPath = $Reg+'\'+$Protocol
$RegPathSrv = $Reg+'\'+$Protocol+'\Server'
$RegPathCl = $Reg+'\'+$Protocol+'\Client'
New-Item -Path $Reg -Name $Protocol -Force | Out-Null
New-Item -Path $RegPath -Name 'Server' -Force | Out-Null
New-Item -Path $RegPath -Name 'Client' -Force | Out-Null
New-ItemProperty -Path $RegPathSrv -Name 'Enabled' -Value 0 -PropertyType DWORD -Force | Out-Null
New-ItemProperty -Path $RegPathCl -Name 'Enabled' -Value 0 -PropertyType DWORD -Force | Out-Null
 
#enable TLS 1.2
$Protocol = 'TLS 1.2'
$RegPath = $Reg+'\'+$Protocol
$RegPathSrv = $Reg+'\'+$Protocol+'\Server'
$RegPathCl = $Reg+'\'+$Protocol+'\Client'
New-Item -Path $Reg -Name $Protocol -Force | Out-Null
New-Item -Path $RegPath -Name 'Server' -Force | Out-Null
New-Item -Path $RegPath -Name 'Client' -Force | Out-Null
New-ItemProperty -Path $RegPathSrv -Name 'Enabled' -Value 1 -PropertyType DWORD -Force | Out-Null
New-ItemProperty -Path $RegPathCl -Name 'Enabled' -Value 1 -PropertyType DWORD -Force | Out-Null
