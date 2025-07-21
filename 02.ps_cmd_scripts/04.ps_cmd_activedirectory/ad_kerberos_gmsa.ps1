#Grant constrained delegation (User Kerberos only)
	$MsaName = 'gMSA' 
	Set-ADAccountControl -Identity $MsaName -TrustedForDelegation $false -TrustedToAuthForDelegation $false
	#Update the Backend Service SPNs in msDS-AllowedToDelegateTo attribute
	Set-ADServiceAccount -Identity $MsaName -Add @{'msDS-AllowedToDelegateTo'=@('MSSQLSvc/computer.contoso.com')}
 
#Grant constrained delegation (User any protocol)
	$MsaName = 'gMSA' 
	Set-ADAccountControl -Identity $MsaName -TrustedForDelegation $false -TrustedToAuthForDelegation $true
	#Update the Backend Service SPNs in msDS-AllowedToDelegateTo attribute
	Set-ADServiceAccount -Identity $MsaName -Add @{'msDS-AllowedToDelegateTo'=@('MSSQLSvc/computer.contoso.com')}
 
#Grant unconstrained delagation
	$MsaName = 'gMSA' 
	Set-ADAccountControl -Identity $MsaName -TrustedForDelegation $true -TrustedToAuthForDelegation $false
	Set-ADServiceAccount -Identity $MsaName -Clear 'msDS-AllowedToDelegateTo'
 
#Remove delagation
	$MsaName = 'gMSA' 
	Set-ADAccountControl -Identity $MsaName -TrustedForDelegation $false -TrustedToAuthForDelegation $false
	Set-ADServiceAccount -Identity $MsaName -Clear 'msDS-AllowedToDelegateTo'
