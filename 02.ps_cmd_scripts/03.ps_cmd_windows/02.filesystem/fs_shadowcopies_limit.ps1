#Limit shadowcopies to 4 GB with PS
    Get-WmiObject Win32_ShadowStorage | forEach-object { $_.MaxSpace = 4194304000; $_.Put() }
 
#Limit shadowcopies to 4 GB with PS from cmd
    powershell -executionpolicy unrestricted -command "Get-WmiObject Win32_ShadowStorage | forEach-object { $_.MaxSpace = 4194304000; $_.Put() }"
 
 
#Limit shadowcopies to 8 GB with PS
    Get-WmiObject Win32_ShadowStorage | forEach-object { $_.MaxSpace = 8388608000; $_.Put() }
 
#Limit shadowcopies to 8 GB with PS from cmd
    powershell -executionpolicy unrestricted -command "Get-WmiObject Win32_ShadowStorage | forEach-object { $_.MaxSpace = 8388608000; $_.Put() }"
