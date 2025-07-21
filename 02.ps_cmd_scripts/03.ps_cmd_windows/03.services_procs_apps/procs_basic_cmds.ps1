#Get uptime of the process
	$CD = (Get-WmiObject Win32_Process | Where-Object ProcessId -eq ((Get-WmiObject Win32_Service | Where-Object Name -like '*ProcessName*').ProcessID)).CreationDate
	$CD.Substring(0,4) + "/" + $CD.Substring(4,2) + "/" + $CD.Substring(6,2) + " " + $CD.Substring(8,2) + ":" + $CD.Substring(10,2) + ":" + $CD.Substring(12,2) 
