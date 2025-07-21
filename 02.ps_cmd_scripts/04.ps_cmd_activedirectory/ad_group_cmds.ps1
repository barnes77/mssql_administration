#Basic check of AD group via CMD
	net group /domain %groupname%
 
#Get all AD groups in OU
	Get-ADGroup -SearchBase "OU=ou_name,DC=CONTOSO,DC=LOCAL" -filter {GroupCategory -eq "Security"} | Select-Object -Property Name | Format-Table
 
#Get all members of all groups matching a pattern
	Get-ADGroup -Filter 'Name -like "*AdGroupNamePatternHere*"' | Get-AdGroupMember <#| Where-Object {$_.Name -notlike '**'} #>| Select-Object -Property Name
 
#Get all members of a group
	Get-ADGroup -Filter 'Name -eq "AdGroupNameHere"' | Get-AdGroupMember <#| Where-Object {$_.Name -notlike '**'} #>| Select-Object -Property Name
 
#Get all groups of AD principal
	Get-ADPrincipalGroupMembership -Identity principal_name | Select-Object -Property Name | Format-Table
