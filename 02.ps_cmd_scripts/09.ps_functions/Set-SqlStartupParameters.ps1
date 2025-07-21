#Based on: github.com/MikeFal/PowerShell/blob/master/Set-SqlStartupParameters.ps1
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SqlWmiManagement') | Out-Null
Function Set-SQLStartupParameters{
	[CmdletBinding(SupportsShouldProcess=$true)]
	Param(
		[string[]] $Instance,
		[string[]] $StartupParameters
	)
	[bool]$SystemPaths = $false
	
	#Parse host and instance names
	$HostName = ($Instance.Split('\'))[0]
	$InstanceName = ($Instance.Split('\'))[1]
 
	#Get service account names, set service account for change
	$ServiceName = If($InstanceName){"MSSQL`$$InstanceName"}Else{'MSSQLSERVER'}
 
	#Use wmi to change account
	$SmoWmi = New-Object Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer $HostName
	$WmiSvc = $SmoWmi.Services | Where-Object {$_.Name -eq $ServiceName}
 
	#Wrangle updated params with existing startup params (-d,-e,-l)
	$OldParams = $WmiSvc.StartupParameters -split ';'
	$NewParams = @()
	Foreach($Param in $StartupParameters){
		If($Param.Substring(0,2) -cmatch '-d|-e|-l'){
			$SystemPaths = $true
			$NewParams += $Param
			$OldParams = $OldParams | Where-Object {$_.Substring(0,2) -cne $Param.Substring(0,2)}
		}
		Else{
			$NewParams += $Param
		}
	}
	$AllParams = @()
	$AllParams += $OldParams | Where-Object {$_.Substring(0,2) -cmatch '-d|-e|-l'}
	$AllParams += $NewParams
	$ParamString = $AllParams -join ';'
 
	#If not -WhatIf, apply the change. Otherwise display an informational message.
	If($PSCmdlet.ShouldProcess($Instance,$ParamString)){
		$WmiSvc.StartupParameters = $ParamString
		$WmiSvc.Alter()
		Write-Host `t"Startup Parameters for $Instance updated."
	}
}
