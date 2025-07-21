#Check formating of all drives
	Get-WmiObject -Query "SELECT Label, Blocksize, Name FROM Win32_Volume WHERE FileSystem='NTFS'" -ComputerName '.' | Select-Object Label, Blocksize, Name 
 
#Perform robocopy with max threads with cmd
	robocopy E:\ X:\ *.* /e /copyall /dcopy:DAT /MT:128
 
#Map share as a drive (creds are stored in: Control Panel\All Control Panel Items\Credential Manager\Edit Windows Credential )
	net use DriveLetterHere \\path_to_share /persistent:no
 
#Unhide hidden files with cmd
	attrib -h -s -a "C:\Hidden"
 
#Get ACL of filesystem location
	Get-Acl -Path 'PathHere' | Select-Object -ExpandProperty Access | Format-Table IdentityReference,AccessControlType,FileSystemRights,IsInherited,InheritanceFlags,PropagationFlags -AutoSize 
 
#Get ACL of shared location
	Get-SmbShareAccess -Name 'ShareName' | Format-Table AccountName,AccessControlType,AccessRight
 
#Get list of SMB shares
	Get-SmbShare | Where-Object {$_.Description -notin ('Remote Admin','Remote IPC') -and $_.Description -notlike '*Default Share*'} | Sort-Object -Property Name | Format-Table Name,ScopeName,Path,Description
 
#Force delete file
	#01 Check your sid
	whoami /user
	#02 Take ownership of the file or of the folder
	takeown /f %filename% /d y
	takeown /f %directoryname% /r/d y
	#03 Grant yourself full control of the file or of the folder
	icacls %filename% /grant *%SID%:F
	icacls %directory% /grant *%SID%:F /t

