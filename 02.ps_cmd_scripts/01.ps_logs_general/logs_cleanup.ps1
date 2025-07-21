#Cleanup system logs with events number > 10 with powershell
	Get-WinEvent -ListLog * -Force | Where-Object {$_.RowCount -gt 10} | % { Wevtutil.exe cl $_.logname }
 
#Cleanup system logs with cmd
	for /F "tokens=*" %1 in ('wevtutil.exe el') DO wevtutil.exe cl "%1"
 
