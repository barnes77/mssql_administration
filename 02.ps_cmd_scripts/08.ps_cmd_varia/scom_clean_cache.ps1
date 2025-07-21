<# Created by Mateusz Wierzbowski
Creation date: 2022/11/22
Aim: Clear SCOM Agent cache (Health Service) and mofcomp sqlmgmproviderxpsp2up#>
 
#Step01 Getting path of HealthService cache
	Write-Host "Getting path of HealthService cache"
	$CachePath = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine',$Server)
	$CachePath = $CachePath.OpenSubKey("SYSTEM\\CurrentControlSet\\services\\HealthService\\Parameters")
	$CachePath = $CachePath.GetValue("State Directory")
 
#Step02 Stopping HealthService service
	Write-Host "Stopping HealthService service"
	Stop-Service -Name HealthService -Force -ErrorAction Stop
 
#Step03 Renaming path of HealthService cache with '_Old' suffix
	Write-Host "Renaming path of HealthService cache with '_Old' suffix"
	Rename-Item -Path $CachePath -NewName "Health Service State_Old"
 
#Step04 Starting HealthService service
	Write-Host "Starting HealthService service"
	Start-Service -Name HealthService
 
#Step05 Deleting renamed, old cache
	Write-Host "Deleting renamed, old cache"
	$CachePathOld = $CachePath + '_Old'
	Remove-Item -Path $CachePathOld -Recurse
 
#Step06 Get all sqlmgmproviderxpsp2up.mof files
$MofFiles = Get-ChildItem -Path 'C:\Program Files (x86)\Microsoft SQL Server\' -Recurse -Force -Include *.mof | 
	Where-Object {$_.Name -eq 'sqlmgmproviderxpsp2up.mof'} | 
		Select-Object -ExpandProperty FullName
 
#Step07 Mofcomp files
ForEach ($MofFile in $MofFiles) {
	cmd.exe /c mofcomp $MofFile
	}
