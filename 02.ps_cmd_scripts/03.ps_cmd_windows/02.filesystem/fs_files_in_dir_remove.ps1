#from DAJK
Get-ChildItem -Path '%filepath%' -Recurse -Force | 
	Where-Object { $_.PSIsContainer -and $_.LastWriteTime -lt (Get-Date).AddDays(-50) -and $_.FullName -notlike '*do.not.delete*' -and $_.Extension -eq '.bak' -and $_.FullName -notlike '*restore*' } | 
	Remove-Item -Force
