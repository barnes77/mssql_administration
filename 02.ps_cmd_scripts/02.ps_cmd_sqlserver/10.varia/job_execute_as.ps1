$User = "CONTOSO\user"
$PWord = ConvertTo-SecureString -String "strong_password" -AsPlainText -Force
$Cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord
Start-Job -Name 'SqlQuery' -ScriptBlock {
	Invoke-SqlCmd -ServerInstance SERVER\INSTANCE -Database DB_NAME_HERE -TrustServerCertificate -Query '
	SELECT @@SERVER;'
	} -Credential $Cred | Out-Null
While((Get-Job | Where-Object {$_.Name -eq 'SqlQuery'}).State -ne 'Completed'){}
Get-Job -Name 'SqlQuery' | Receive-Job -Keep | Select-Object -Property line | Format-Table
Remove-Job -Name 'SqlQuery'
