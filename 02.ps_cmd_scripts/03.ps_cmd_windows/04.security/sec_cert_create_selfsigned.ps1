##Create self-signed certificate in LocalMachin store
$Subject = 'DBA07.SQLLAB.local' #FQDN to be used as DNS value and certificate's friendly name
$params = @{
	CertStoreLocation = 'Cert:\LocalMachine\My'
	DnsName = "DBA07.SQLLAB.local", "CONN01_DNS_APTR.SQLLAB.local", "CONN01_DNS_CNAME01.SQLLAB.local" #Should include FQDN of the host and can include SAN (Subject Alternative Names) separated by coma
	NotAfter = (Get-Date).AddYears(2)
	FriendlyName = $Subject
	Subject = $Subject
	KeySpec = 'KeyExchange'
}
New-SelfSignedCertificate @params
$CertPwd = ConvertTo-SecureString "5QpdPHqhzvvaeKZ7B6cM" -AsPlainText -force
 
##Export certificate as .pfx
$File = 'D:\AdminDB\'+$Subject.ToLower()+'.pfx' #Output location for pfx
$Thumbprint = (Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {$_.Subject -match $Subject}).Thumbprint;
$Cert = 'cert:\LocalMachine\My\'+$Thumbprint
Export-PFXCertificate -Cert $Cert -FilePath $File -Password $CertPwd -ChainOption EndEntityCertOnly 
#EndEntityCertOnly is used to prevent including whole certification chain which can result in error 'Selected certificate name does not match FQDN of this hostname'
 
##Optional: Reimport certifacte from .pfx into LocalMachine store, root
Import-PfxCertificate -FilePath $File cert:\LocalMachine\root -Password $CertPwd
 
##Optional: Remove .pfx
#Remove-Item -Path $File -Force
