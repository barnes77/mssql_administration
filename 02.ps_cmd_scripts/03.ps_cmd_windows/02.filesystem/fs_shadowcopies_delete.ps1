#Delete shadowcopies with PS
    Get-WmiObject Win32_Shadowcopy -filter ClientAccessible='false' | ForEach-object { $_.Delete() }
 
#Delete shadowcopies with PS from cmd
    powershell -executionpolicy unrestricted -command "Get-WmiObject Win32_Shadowcopy -filter ClientAccessible=''false'' | ForEach-object { $_.Delete() } "

