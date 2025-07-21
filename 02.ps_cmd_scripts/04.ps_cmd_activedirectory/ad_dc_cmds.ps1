#Find netlogon server via cmd
	set l
 
#Find netlogon server via PS
	$env:LOGONSERVER
 
#Find list of Domain Controllers in a domain with PS
	Get-ADDomainController -Discover -Domain 'domain'
 
#Find name of PDC via cmd
	nltest /dcname:%domain.com%
 
#Find list of Domain Controllers in a domain via cmd
	nltest /dclist:%domain.com%
 
#Test secure connection to DC via cmd
	nltest /sc_query:%domain.com%
 
#Test secure connection to DC via PS
	Test-ComputerSecureChannel -Server "%DCNameHere%.%domain.com%"
 
#Find list of all domain trusts via cmd
	nltest domain_trusts /all_trusts
 
#Synchronize all DC (pull request) via cmd
	repadmin /syncall dc1 /Aed
 
#Synchronize all DC (push request) via cmd
	repadmin /syncall dc1 /APed
