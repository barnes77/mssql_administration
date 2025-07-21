<# Created by Mateusz Wierzbowski
Creation date: 2022/07/22
Aim: A script to run against multiple servers and gather information about .bak, .trn, KB*.exe files older than 12 days #>
 
$Remote_Servers = @("DBA02","DBA03","DBA04","DBA05","DBA06","DBA07")
$Subject = "Report on old backup/installation files"
$Smtp = "ip_of_smtp"
$Mail_To = "adres@domain.net"
$Mail_From = "adres@domain.net"
 
#Get invocation path
#$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ScriptDir = "D:\DBA\report\"
 
#Creating a report file
$Date = (Get-Date).ToString('yyyyMMdd_hhmmss')
 
#Choose output dir
$Report = "$ScriptDir\BackupFilesReport_"+$Date+".txt"
 
#Create report file
$Header = "Host $([char]0009) File Name $([char]0009) Creation Date $([char]0009) Size MB $([char]0009) Location"
Write-Output $Header | Set-Content $Report
 
#Create command to be executed
$Command = {
	$Drive_Letters = Get-WmiObject Win32_LogicalDisk | Select-Object -Expand DeviceID
	(Get-ChildItem -Path $Drive_Letters -file -Include *.bak, *.trn, *KB*.exe -Recurse -ErrorAction SilentlyContinue)|
	Where-Object {$_.CreationTime -gt (Get-Date).AddDays(-12) }|
	Foreach-Object {$env:computername+$([char]0009)+$_.Name+$([char]0009)+$_.CreationTime+$([char]0009)+([math]::Round( ($_.Length/(8*1024*1024)) , 2 ))+$([char]0009)+$_.FullName}
}
 
#Execute command against remote servers
Foreach ($Server in $Remote_Servers) {
	Invoke-Command -ScriptBlock $Command -ComputerName $Server | Out-File -FilePath $Report -Encoding ASCII -Append
}
 
#Send email with attachment
Send-MailMessage -From $Mail_From -To $Mail_To -Subject $Subject -SmtpServer $Smtp -Attachments $Report -Body $Body;
