#Skip if you have ActiveDirectory module already available
	Import-Module ActiveDirectory
 
#Create an gMSA
	New-AdServiceAccount -Name 'full_gMSA' -DNSHostName 'gMSA.contoso.com' -SamAccountName 'gMSA' -PrincipalsAllowedToRetrieveManagedPassword 'host_group' -ManagedPasswordIntervalInDays 30 -TrustedForDelegation $false -Enabled:$true
	#-RestrictToSingleComputer #This option causes creation of standalone MSA
	#-AccountPassword (ConvertTo-SecureString -AsPlainText "p@ssw0rd" -Force) #This parameter causes creation with non-random password
 
#Verify that gMSA account exists
	Get-AdServiceAccount –Identity 'gMSA'
 
#Verify most important MSA properties
	Get-AdServiceAccount –Identity 'gMSA' -Properties Name,PrincipalsAllowedToRetrieveManagedPassword,ManagedPasswordIntervalInDays,TrustedForDelegation,TrustedToAuthForDelegation,KerberosEncryptionType,RestrictToSingleComputer | Format-List
 
#Test gMSA on the host where it is to be used
	Test-AdServiceAccount –Identity 'gMSA'
 
#Install gMSA on the host where it is to be used
	Install-AdServiceAccount –Identity'gMSA'
	#-AccountPassword (ConvertTo-SecureString -AsPlainText "p@ssw0rd" -Force) #This parameter is needed if gMSA was created with non-random password
 
#If you cannot test or install it, you are lacking Powershell tools (Run as admin / No reboot required)
	Install-WindowsFeature RSAT-AD-Powershell
