#Get report on GPOs applied on local host with CMD
	gpresult /h C:\temp\gpresult.html /scope:computer
 
#Get last 10 modified GPOs
	Get-GPO -All | Sort-Object ModificationTime -desc | Select-Object -Property DisplayName,CreationTime,ModificationTime -First 10 | Format-Table
 
#Get last 10 created GPOs
	Get-GPO -All | Sort-Object CreationTime -desc | Select-Object -Property DisplayName,CreationTime,ModificationTime -First 10 | Format-Table
