#Basic check of AD user via CMD
	net user /domain %login%
 
#Find AD User in another domain using hostname of Domain Controller
	Get-ADUser -Server DC_FQDN -Identity ADAccName
 
	Get-ADServiceAccount -Server DC_FQDN -Identity MSAAccName
 
#Find SID of AD User with PS
	Get-ADUser -Identity ADAccName | Select-Object SID
 
	Get-ADServiceAccount -Identity MSAAccName | Select-Object SID
 
#Find SID of AD User with cmd
	wmic useraccount where name='ADAccName' get sid
 
#Find AD User in another domain using SID
	Get-ADUser -Server DC_FQDN -Filter {SID -eq 'SID'}
 
	Get-ADServiceAccount -Server DC_FQDN -Filter {SID -eq 'SID'}

#Create AD User
	New-ADUser -Name NameHere -GivenName GivenNameHere -Surname SurnameHere -UserPrincipalName IDHere -SamAccountName IDHere -Path OUPathHere -Enabled $true -AccountPassword (ConvertTo-SecureString PasswordHere -AsPlainText -force)
	Add-ADGroupMember -Identity ADGroupHere -Members UserPrincipalNameHere
 
#Logoff user from server
	qwinsta [-server ServerNameHere]
	logoff SessionIDHere
