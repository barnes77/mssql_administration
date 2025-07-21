#Get IP addresses on which host is listening
	netsh interface ip show address 
 
#Show routing
	route print
 
#Add persistent routing
	route -p add %IPAddress% MASK %MaskIPAddress% %GatewayIPAddress% metric 1
 
#Show ARP table
	arp /a
 
#Delete single ARP entry
	arp /d %ipaddress% 
 
#Cleanup ARP cache
	arp /d
 
#Cleanup ARP cache via netsh
	netsh interface ip delete arpcache
 
#Get URLACL reservations
	netsh http show urlacl
 
#Delete URLACL reservation (http://+:8082/ as an example)
	netsh http delete urlacl url=http://+:8082/
 
#Reserver URLACL (http://+:8088/ for SSRS 2017+ as an example)
	netsh http add urlacl url=http://+:8088/ user="NT SERVICE\SQLServerReportingServices"
