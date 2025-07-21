# Created by Mateusz Wierzbowski
# Creation date: 07/02/2019
# Aim: Create text file to test disk monitoring
 
#ChooseDriveLetter
$Drive = 'C:'
$New_File_Size = Get-WmiObject -Class Win32_logicaldisk -Filter "DeviceID = '$Drive'"| ForEach-Object {($_.Size-$_.FreeSpace)-($_.Size/10)}
$New_File = "$Drive\TestDiskMonitoring.txt"
New-Item $New_File -ItemType File -ErrorAction SilentlyContinue -Force
$f = New-Object System.IO.FileStream $New_File, Create, ReadWrite
$f.SetLength("$New_File_Size")
$f.Close()
