#Online installation
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Install-Module dbatools
 
#Getting product keys (Sql2022 not supported)
$Hostname = '' #name of windows server
Get-DbaProductKey -ComputerName $Hostname
 
#Exporting logins
$Instance = 'SERVER\INSTANCE'
$SqlFile = 'C:\temp\logins.sql'
Export-DbaLogin -SqlInstance $Instance -Path $SqlFile
 
#Migrate instance using param splatting
$Params = @{
	Source = 'SERVER\INSTANCE' #source instance
	Destination = 'SERVER\INSTANCE' #target instance
	BackupRestore = $true
	SharedPath = '\\server\sharedfolder' #folder used for backups
	Exclude = 'BackupDevices','SysDbUserObjects','Credentials'
}
Start-DbaMigration @Params -Force | Select-Object * | Out-GridView
 
#Regain access to locked out instance
$Instance = 'SERVER\INSTANCE'
$SqlLogin = 'sqladmin' #name of sql login to be created with sysadmin rights
Reset-DbaAdmin -SqlInstance $Instance -Login $SqlLogin -Verbose
 
#Get trace flags
$Instance = 'SERVER\INSTANCE'
Get-DbaStartupParameter -SqlInstance server1\instance1
 
#Add trace flags
$Instance = 'SERVER\INSTANCE'
$Flags = '460,3226,6534'
Set-DbaStartupParameter -SqlInstance $Instance -TraceFlag $Flags
 
#Replace trace flags
$Instance = 'SERVER\INSTANCE'
$Flags = '460,3226,6534'
Set-DbaStartupParameter -SqlInstance $Instance -TraceFlag $Flags -TraceFlagOverride
 
#Sync between replicas using splatting
$Params = @{
	Source = 'SERVER\INSTANCE' #source instance
	AvailabilityGroup = 'AoGroupName'
	#Destination = 'SERVER\INSTANCE' #target instance // if not used will sync all replicas
	ExcludeType = LinkedServers #will include: SpConfigure, CustomErrors, Credentials, DatabaseMail, LinkedServers,Logins, LoginPermissions, SystemTriggers, DatabaseOwner, AgentCategory,AgentOperator, AgentAlert, AgentProxy, AgentSchedule, AgentJob
	ExcludeJob = syspolicy_purge_history
}
Sync-DbaAvailabilityGroup @Params
