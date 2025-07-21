cd c:\windows\system32
lodctr /R
cd c:\windows\sysWOW64
lodctr /R
 
WINMGMT.EXE /RESYNCPERF
 
Get-Service -Name "pla" | Restart-Service -Verbose
 
Get-Service -Name "winmgmt" | Restart-Service -Force -Verbose
