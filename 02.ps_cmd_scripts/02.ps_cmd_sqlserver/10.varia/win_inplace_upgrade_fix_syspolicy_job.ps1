#Fix missing registry paths to allow "syspolicy_purge_history" Agent job to finish after OS inplace upgrade Win2012>Win2016 with SQL2014 installed
	New-Item -Path 'HKLM:SOFTWARE\Microsoft\PowerShell\1\ShellIds\' -Name 'Microsoft.SqlServer.Management.PowerShell.sqlps120' -Force | Out-Null
	New-ItemProperty -Path 'HKLM:SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.SqlServer.Management.PowerShell.sqlps120' -Name 'ExecutionPolicy' -Value 'RemoteSigned' -PropertyType String -Force | Out-Null
	New-ItemProperty -Path 'HKLM:SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.SqlServer.Management.PowerShell.sqlps120' -Name 'Path' -Value 'C:\Program Files (x86)\Microsoft SQL Server\120\Tools\Binn\SQLPS.exe' -PropertyType String -Force | Out-Null
 
#Fix missing registry paths to allow "syspolicy_purge_history" Agent job to finish after OS inplace upgrade Win2012>Win2016 with SQL2016 installed
	New-Item -Path 'HKLM:SOFTWARE\Microsoft\PowerShell\1\ShellIds\' -Name 'Microsoft.SqlServer.Management.PowerShell.sqlps130' -Force | Out-Null
	New-ItemProperty -Path 'HKLM:SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.SqlServer.Management.PowerShell.sqlps130' -Name 'ExecutionPolicy' -Value 'RemoteSigned' -PropertyType String -Force | Out-Null
	New-ItemProperty -Path 'HKLM:SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.SqlServer.Management.PowerShell.sqlps130' -Name 'Path' -Value 'C:\Program Files (x86)\Microsoft SQL Server\130\Tools\Binn\SQLPS.exe' -PropertyType String -Force | Out-Null
 
