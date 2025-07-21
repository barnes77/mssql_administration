Get-ChildItem -Path Cert:\LocalMachine\My -Recurse |
	Where-Object {$_.PSISContainer -eq $false} | Format-List -Property Subject,Issuer,NotBefore,NotAfter,FriendlyName,SerialNumber,Thumbprint,
	@{
		Name = "Algorithm"
	Expression = {$_.SignatureAlgorithm.FriendlyName}
	},
	@{
		Name = "KeyLength"
		Expression = {$_.PublicKey.Key.KeySize}
	}
