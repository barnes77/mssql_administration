#Create local firewall rule with cmd
	netsh advfirewall firewall add rule name=”RuleName” dir=in action=allow protocol=TCP localport=PortNumber profile=any 
 
#Create set of local firewall rules for SQL Server with cmd
	netsh advfirewall firewall add rule name="SQL Server Browser database (UDP 1434 IN)" dir=in action=allow protocol=UDP localport=1434 profile=any
	netsh advfirewall firewall add rule name="SQL Server Browser database (UDP 1434 OUT)" dir=out action=allow protocol=UDP remoteport=1434 profile=any
	netsh advfirewall firewall add rule name="SQL Server Connection (TCP 1433)" dir=in action=allow protocol=TCP localport=1433 profile=any
	netsh advfirewall firewall add rule name="SQL Server DAC Connection (TCP 1533)" dir=in action=allow protocol=TCP localport=1533 profile=any
	netsh advfirewall firewall add rule name="SQL Server Analysis Services Connection (TCP 2382-2383)" dir=in action=allow protocol=TCP localport=2382-2383 profile=any
	netsh advfirewall firewall add rule name="SQL Server Integration Services Connection (TCP 135)" dir=in action=allow protocol=TCP localport=135 profile=any
 
#Create rules to allow traffic to AOAG entrypoints (5022-5030)
	netsh advfirewall firewall add rule name=”SQL Server AOAG synchronization” dir=in action=allow protocol=TCP localport=5022-5030 profile=any
 
#Create MSDTC rules with cmd
	netsh advfirewall firewall set rule group="Distributed Transaction Coordinator" new enable=yes
