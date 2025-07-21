#source: jonathanmedd.net/2014/02/testing-for-the-presence-of-a-registry-key-and-value.html
Function Test-RegistryValue {
	Param (
		[Parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()]$Path,
		[Parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()]$Value
	)
	Try {
		Get-ItemProperty -Path $Path | Select-Object -ExpandProperty $Value -ErrorAction Stop | Out-Null
		Return $true
	}
	Catch {
		Return $false
	}
}
