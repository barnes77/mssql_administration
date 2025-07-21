Function Get-RandomPassword { #source: arminreiter.com/2021/07/3-ways-to-generate-passwords-in-powershell/
	Param (
		[Parameter(Mandatory)]
		[int] $Length
	)
	$CharSet = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789+-[*=@$^%#?.'.ToCharArray()
	$Rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
	$Bytes = New-Object byte[]($Length)
 
	$Rng.GetBytes($Bytes)
 
	$Result = New-Object char[]($Length)
 
	For ($i = 0 ; $i -lt $Length ; $i++) {
		$Result[$i] = $CharSet[$Bytes[$i]%$CharSet.Length]
	}
 
	Return (-join $Result)
}
