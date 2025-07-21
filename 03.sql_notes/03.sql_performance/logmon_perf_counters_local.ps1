#Based on https://www.mssqltips.com/sqlservertip/1722/collecting-performance-counters-and-using-sql-server-to-analyze-the-data/

#Step01: Log to the server to be monitored and run directly following script to get the general list of counters related to SQL performance
	#Create counterset file
		$CounterSet = "C:\temp\CounterSet.txt"
		New-Item $CounterSet -ItemType file -ErrorAction SilentlyContinue -Force
	
	#Get SQL services names
		$instance = Get-Service *SQL* | Where-Object {$_.Status -eq "Running"} | Foreach-Object {$_.Name}
	
	#Add non-instance-specific counters
		Set-Content -Path $CounterSet -Value "\Memory\Available MBytes"
		Add-Content -Path $CounterSet -Value "\Physical Disk(*)\Avg. Disk sec/Read"
		Add-Content -Path $CounterSet -Value "\Physical Disk(*)\Avg. Disk sec/Write"
		Add-Content -Path $CounterSet -Value "\Physical Disk(*)\Disk Reads/sec"
		Add-Content -Path $CounterSet -Value "\Physical Disk(*)\Disk Writes/sec"
		Add-Content -Path $CounterSet -Value "\Processor(*)\% Processor Time"
		Add-Content -Path $CounterSet -Value "\Process(*)\% Processor Time"
		Add-Content -Path $CounterSet -Value "\System\Processor Queue Length"
		
		Foreach ($object in $instance)
			{
			#Add counters for default instance
			if ($object -eq "MSSQLSERVER")
				{
				Add-Content -Path $CounterSet -Value "\SQLServer:General Statistics\User Connections"
				Add-Content -Path $CounterSet -Value "\SQLServer:Memory Manager\Memory Grants Pending"
				Add-Content -Path $CounterSet -Value "\SQLServer:SQL Statistics\Batch Requests/sec"
				Add-Content -Path $CounterSet -Value "\SQLServer:SQL Statistics\SQL Compilations/sec"
				Add-Content -Path $CounterSet -Value "\SQLServer:SQL Statistics\SQL Re-Compilations/sec"
				}
			#Add counters for named instances
			elseif ($object -like "MSSQL$*")
				{
				Add-Content -Path $CounterSet -Value "\$object foo:General Statistics\User Connections"
				Add-Content -Path $CounterSet -Value "\$object foo:Memory Manager\Memory Grants Pending"
				Add-Content -Path $CounterSet -Value "\$object foo:SQL Statistics\Batch Requests/sec"
				Add-Content -Path $CounterSet -Value "\$object foo:SQL Statistics\SQL Compilations/sec"
				Add-Content -Path $CounterSet -Value "\$object foo:SQL Statistics\SQL Re-Compilations/sec"
				}
			}
	
	#Clear the counters for named instances
		(Get-Content $CounterSet) | ForEach-Object {$_.replace(" foo","")}|Set-Content -Path $CounterSet
		
#Step02: Create Collection from CMD

	logman create counter MyCollection -s %computername% -cf "C:\temp\CounterSet.txt" -max 200 -rf 10:00
	
#Step03: Start logmon from CMD

	logman MyCollection start
	
#Step04: Stop logmon from CMD
	
	logman MyCollection stop

#Step05: Delete Collection from CMD
	
	logman delete MyCollection

#Step06: Access PerfMon results in %systemdrive%\PerfLogs\Admin

