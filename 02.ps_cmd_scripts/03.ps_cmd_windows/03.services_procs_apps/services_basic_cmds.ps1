#Windows Time Services commands
	#Stop Windows time service
		net stop w32time
	#Start Windows time service
		net start w32time
	#Restart Windows time service
		net stop w32tim
		net start w32time
	#Synchronize time with source
		w32tm /resync
	#Get list of DCs with which time can be synchronized
		w32tm /monitor
	#Remove all past configuration of w32time from registry
		w32tm /unregister
	#Register w32time and restore default time settings
		w32tm /register
	#Find source of time
		w32tm /query /source
	#Find status of time synchronization
		w32tm /query /status
	#Find configuration of w32tm
		w32tm /query /configuration
	#Update configuration
		w32tm /config /update
	#Force time synchronization from domain
		w32tm /config /syncfromflags:domhier /update
 
#Windows Remote Management
	#Get config of WinRM (Windows Remote Management)
		winrm get winrm/config
