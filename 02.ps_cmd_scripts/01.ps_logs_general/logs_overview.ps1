#Get overview of system logs
Get-WinEvent -ListLog * -Force | Where-Object {$_.FileSize -ne $null} | 
Sort-Object -Property $_.FileSize -Descending | 
Select-Object LogName,@{name='Size';expression={$_.FileSize/1MB}},LastWriteAccess 

