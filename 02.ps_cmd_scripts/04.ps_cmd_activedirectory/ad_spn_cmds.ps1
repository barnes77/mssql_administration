#Create SPN with PS (single)
	Set-ADUser -Identity ADAccName -ServicePrincipalNames @{Add='MSSQLSvc/FQDN:PortNumber'}
 
	Set-ADServiceAccount -Identity MSAAccName -ServicePrincipalNames @{Add='MSSQLSvc/FQDN:PortNumber'}
 
#Create SPN with PS (multiple)
	Set-ADUser -Identity ADAccName -ServicePrincipalNames @{Add='MSSQLSvc/FQDN:PortNumber','MSSQLSvc/FQDN:InstanceName'}
 
	Set-ADServiceAccount -Identity MSAAccName -ServicePrincipalNames @{Add='MSSQLSvc/FQDN:PortNumber','MSSQLSvc/FQDN:InstanceName'}
#Create SPN with cmd
	setspn -s MSSQLSvc/FQDN:PortNumber ADAccName
 
	setspn -s MSSQLSvc/FQDN:InstanceName ADAccName
 
 
#Remove SPN with PS (single)
	Set-ADUser -Identity ADAccName -ServicePrincipalNames @{Remove='MSSQLSvc/FQDN:PortNumber'}
 
	Set-ADServiceAccount -Identity MSAAccName -ServicePrincipalNames @{Remove='MSSQLSvc/FQDN:PortNumber'}
#Remove SPN with PS (all)
	Set-ADUser -Identity ADAccName -ServicePrincipalNames $null
 
	Set-ADServiceAccount -Identity MSAAccName -ServicePrincipalNames $null
#Remove SPN with cmd
	setspn -d MSSQLSvc/FQDN:PortNumber ADAccName
 
	setspn -d MSSQLSvc/FQDN:InstanceName ADAccName
 
 
#Find all SPNs of an account with PS
	Get-ADUser -Identity ADAccName -Property ServicePrincipalNames | Select-Object -ExpandProperty ServicePrincipalNames 
 
	Get-ADServiceAccount -Identity MSAAccName -Property ServicePrincipalNames | Select-Object -ExpandProperty ServicePrincipalNames 
#Find all SPNs of an account with cmd
	setspn -l ADAccName
 
 
#Find Account to which SPN is assigned with PS (if it exists)
	Get-ADObject -Filter { ServicePrincipalName -eq 'MSSQLSvc/FQDN:PortNumber' } | Select-Object -ExpandProperty Name
 
	Get-ADObject -Filter { ServicePrincipalName -like 'MSSQLSvc/*' } | Select-Object -ExpandProperty Name
#Find Account to which SPN is assigned with PS (if it exists)
	setspn -q SPNclass/SPNName
