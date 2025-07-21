#Get-LocalUserRemotely -Computer $env:computername -Name 'BsaUser'
#If(!(Get-LocalUserRemotely -Computer DBA07 -Name 'BsaUser2')){1}
Function Get-LocalUserRemotely {
	Param (
		[Parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()]$Computer,
		[Parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()]$Name
		
	)
	Get-WmiObject win32_UserAccount -ComputerName $Computer | Where-Object {$_.Name -eq $Name -and $_.Domain -eq $_.PSComputerName} | Select-Object -ExpandProperty Name
}

