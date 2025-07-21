#Get FSMO roles of the DCs via CMD
	netdom query fsmo
#Get forest level FSMO roles of the DCs via PS
	Get-ADForest sqllab.local | Format-Table SchemaMaster,DomainNamingMaster
#Get domain level FSMO roles of the DCs via PS
	Get-ADDomain sqllab.local | format-table PDCEmulator,RIDMaster,InfrastructureMaster
 
#Transfer PDCEmulator FSMO role via PS
	Move-ADDirectoryServerOperationMasterRole -Identity "dc1" PDCEmulator
#Transfer RIDMaster FSMO role via PS
	Move-ADDirectoryServerOperationMasterRole -Identity "dc1" RIDMaster
#Transfer InfrastrctureMaster FSMO role via PS
	Move-ADDirectoryServerOperationMasterRole -Identity "dc1" Infrastructuremaster
#Transfer DomainNamingMaster FSMO role via PS
	Move-ADDirectoryServerOperationMasterRole -Identity "dc1" DomainNamingmaster
#Transfer SchemaMaster FSMO role via PS
	Move-ADDirectoryServerOperationMasterRole -Identity "dc1" SchemaMaster
 
#Add computer to domain via PS
	Add-Computer –DomainName "sqllab.local"  -OUPath "OU=testOU,DC=domain,DC=com" -Restart
