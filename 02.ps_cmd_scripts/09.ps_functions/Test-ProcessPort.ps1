Function Test-ProcessPort {
	Try{
		Get-Process -Id (Get-NetTCPConnection -LocalPort 1433 -ErrorAction SilentlyContinue).OwningProcess | Select-Object -ExpandProperty ProcessName 
		Return $Proc
	}
	Catch{
		Return $null
	}
}
 
If ((Test-Path -Path "C:\temp\port_check.txt") -eq $false) {
	New-Item -Path "C:\temp\port_check.txt" -ItemType file -Force | Out-Null
}
 
While(1 -eq 1) {
	$Date = Get-Date -format "yyyyMMdd HH:mm:ss"
 
	$Proc = Test-ProcessPort
 
	If ($Proc -ne 'sqlservr' -and $null -ne $Proc){
		Out-File -FilePath "C:\temp\port_check.txt" -Append -InputObject "$Date - $Proc"
	}
 
	$Proc = $null
 
	Start-Sleep 2
}
