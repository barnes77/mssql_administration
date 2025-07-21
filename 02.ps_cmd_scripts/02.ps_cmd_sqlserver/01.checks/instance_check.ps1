#.\instance_check.ps1 
#.\instance_check.ps1 -TempFolder E:\DBA\
 
<# Created by Mateusz Wierzbowski
Creation date: 2021/03/12-14
Aim: Carry out basic checks before patching or doing an inplace upgrade of an SQL instance
	Part 01: Run FindSQLInstalls.vbs and verify its results - source: docs.microsoft.com/en-us/troubleshoot/sql/install/restore-missing-windows-installer-cache-files#Script
	Part 02: Perform basic checks of SQL service accounts (if the password has expired, SQL won't get up after the reboot)
	Part 03: Check size of systemDBs (if they are enormously large, it can take a lot of time for archiving them before patching/upgrade)
	Part 04: Checking states of databases for additional features
	Part 05: Checking registry entries for default paths
	Part 06: Get free space on drives C:, D: and E:
	Part 07: Check if there is no sign of risk of prolonged reboot time (huge size of Datastore and long uptime)
	Part 08: Check if there's any pending reboot
Note: if there's no c:\temp or c:\tmp, you can specify the folder where temp files will be placed

V1.0: 2021/03/12-14
V2.0: 2021/09/27
V3.0: 2021/11/03
#>

<#PART 00 - Definition of params, checking paths, creating functions#>
Param(
	[Parameter(Mandatory=$false)] [string]$TempFolder #TempFolder
)

#Verify if the script is run as admin
If(([Security.Principal.WindowsIdentity]::GetCurrent().Groups -contains 'S-1-5-32-544') -eq $false){
	throw 'The script needs to be run as administrator.'
}

#Looking for temp folder on the drive c
Write-Host "`tChecking if a temp folder was set using `$TempFolder param. If yes, also verifying if the path exists."
If(!($TempFolder) -eq $false) {
	$Target_Folder = $TempFolder
	If((Test-Path $Target_Folder) -eq $false){
		New-Item $Target_Folder -Force -ItemType "Directory" | Out-Null
		Write-Host "Temp folder "$Target_Folder" was created."
	}
}
Else{
	If((Test-Path 'C:\Temp\') -eq $true){$Target_Folder = 'C:\Temp\'}
	Elseif((Test-Path 'C:\TMP\') -eq $true){$Target_Folder = 'C:\TMP\'}
	Else{Write-Error "No temp folder on the drive C was found. Consider specifying a target folder using -TempFolder param." -ErrorAction Stop}
}
#source: www.jonathanmedd.net/2014/02/testing-for-the-presence-of-a-registry-key-and-value.html
function Test-RegistryValue {
	param (
	[parameter(Mandatory=$true)]
	[ValidateNotNullOrEmpty()]$Path,
	
	[parameter(Mandatory=$true)]
	[ValidateNotNullOrEmpty()]$Value
	)
	try {
	Get-ItemProperty -Path $Path | Select-Object -ExpandProperty $Value -ErrorAction Stop | Out-Null
	return $true
	}
	catch {
	return $false
	}
}

<# PART 01 - Check Installer Cache #>
#Setting a filename for VBS Script
Write-Host "`n`tCreating a file for VBS Script."
$Vbs_Check_File = $Target_Folder+'FindSQLInstalls.vbs'
If((Test-Path $Vbs_Check_File) -eq $true){
	Write-Host "`tFile with VBS script already exists. Current one will be removed and a new one will be created."
	Remove-Item -Path $Vbs_Check_File -Force
	}
New-Item -Path $Vbs_Check_File -ItemType "file" | Out-Null
#Actual VBS statement - for PS code go to line 380
'
'' Copyright © Microsoft Corporation. All Rights Reserved.
'' This code released under the terms of the
'' Microsoft Public License (MS-PL, http://opensource.org/licenses/ms-pl.html.)
	
	
On Error Resume Next
	
Dim arrSubKeys, arrSubKeys2
Dim objFSO, objShell, objFile, objReg, objConn, objExec
Dim strComputer, strKeyPath, strNewSource
Dim strWorkstationName, strDBPath, strSubKey, strSubKey2(), strKeyPath02, strRetValue00
Dim strRetValue01, strRetValue02, strRetValNew02, strRetValNew03, strRetValNew04, strRetValNew05, strRetValNew06, strRetValNew07, strRetValNew08, strRetValNew09, strRetValue10, strRetValNew10, strRetValNew11, strRetValNew12, strRetValNew13, strRetValNew14, strRetValNew14a, strRetValNew14b, strRetValNew15, strRetValNew15a, strRetValNew15b, strRetValNew16, strRetValNew17, strRetValNew18
	
Const HKCR = &H80000000 ''HKEY_CLASSES_ROOT
Const HKLM = &H80000002 ''HKEY_LOCAL_MACHINE
Const ForReading = 1, ForWriting = 2, ForAppEnding = 8
	
'' Checking for Elevated permissions
Dim oShell, oExec
szStdOutszStdOut = ""
Set oShell = CreateObject("WScript.Shell")
Set oExec = oShell.Exec("whoami /groups")
	
Do While (oExec.Status = cnWshRunning)
	WScript.Sleep 100
		if not oExec.StdOut.AtEndOfStream Then
				szStdOut = szStdOut & oExec.StdOut.ReadAll
		end If
Loop
	select case oExec.ExitCode
	case 0
		if not oExec.StdOut.AtEndOfStream Then
			szStdOut = szStdOut & oExec.StdOut.ReadAll
		End If
		If instr(szStdOut,"Mandatory Label\High Mandatory Level") Then
				wscript.echo "Elevated, executing script and gathering requested data"
		Else
			if instr(szStdOut,"Mandatory Label\Medium Mandatory Level") Then
			Wscript.echo "Not Elevated must run from Administrative commmand line."
		Else
			Wscript.echo "Gathering requested data..."
			end If
		End If
	case Else
		if not oExec.StdErr.AtEndOfStream Then
			wscript.echo oExec.StdErr.ReadAll
		end If
		end select
	
''
'' Leaving strNewSource will result in no search path updating.
'' Currently DO NOT EDIT these.
strNewSource = ""
strNewRTMSource = ""
	
'' Define string values
strComputer = "."
strSQLName = "SQL"
strDotNetName = ".NET"
strVStudioName = "Visual Studio"
strXML = "XML"
strOWC = "Microsoft Office 2003 Web Components"
strKeyPath = "Installer\Products"
strKeyPath2 = "SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products"
strNValue00 = "ProductName"
strNValue01 = "PackageName"
strNValue02 = "LastUsedSource"
strNValue03 = "InstallSource"
strNValue04 = "LocalPackage"
strNValue05 = "DisplayVersion"
strNValue06 = "InstallDate"
strNValue07 = "UninstallString"
strNValue08 = "PackageCode"
strNValue09 = "MediaPackage"
strNValue10 = "InstallSource"
strNValue11 = "AllPatches"
strNValue12 = "NoRepair"
strNValue13 = "MoreInfoURL"
strNValue14 = "PackageName"
strNValue15 = "LastUsedSource"
strNValue16 = "Uninstallable"
strNValue17 = "DisplayName"
strNValue18 = "Installed"
	
If WScript.arguments.count <> 1 Then
	WScript.echo "Usage: cscript " & WScript.scriptname & " outputfilename.txt"
	WScript.quit
End If
	
''--Setup the output file
Set fso = CreateObject("Scripting.FileSystemObject")
Set txtFile = fso.OpenTextFile(WScript.arguments(0), ForWriting, True)
If err.number <> 0 Then
	WScript.echo "Error 0x" & myHex(err.number,8) & ": " & err.source & " - " & err.description
	WScript.quit
End If
	
txtFile.writeline "Products installed on the local system"
txtFile.writeline " "
txtFile.writeline " "
	
	
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objShell = WScript.CreateObject("WScript.Shell")
	
''--Set up the registry provider.
Set objReg = GetObject("winmgmts:\\" & strComputer & _
"\root\default:StdRegProv")
	
Set wiInstaller = CreateObject("WindowsInstaller.Installer")
	
''--Enumerate the "installer\products" key on HKCR
objReg.EnumKey HKCR, strKeyPath, arrSubKeys
	
For Each strSubKey In arrSubKeys
	
'' Define the various registry paths
strProduct01 = "Installer\Products\" & strSubKey
strKeyPath02 = "Installer\Products\" & strSubKey & "\SourceList"
strKeyPath03 = "Installer\Products\" & strSubKey & "\SourceList\Media"
strInstallSource = "SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\" & strSubKey & "\InstallProperties\"
strInstallSource2 = "SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\" & strSubKey & "\patches\"
strInstallSource3 = "SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Patches"
strInstallSource5 = "SOFTWARE\Classes\Installer\Patches\"
strInstallSource6 = "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"
strInstallSource7 = "SOFTWARE\Microsoft\Microsoft SQL Server\"
strInstallSource8 = "SOFTWARE\Wow6432Node\Microsoft\Microsoft SQL Server\"
	
'' Pull the intial values
objReg.GetStringValue HKCR, strProduct01, strNValue00, strRetValue00
objReg.GetStringValue HKCR, strKeyPath02, strNValue01, strRetValue01
objReg.GetStringValue HKCR, strKeyPath02, strNValue02, strRetValue02
strRetValNew02 = Mid(strRetValue02, 5)
objReg.GetStringValue HKCR, strKeyPath03, strNValue09, strRetValue09
strRetValue10 = strNewRTMSource & strRetValue09
objReg.GetStringValue HKLM, strInstallSource, strNValue03, strRetValNew03
objReg.GetStringValue HKLM, strInstallSource, strNValue04, strRetValNew04
objReg.GetStringValue HKLM, strInstallSource, strNValue05, strRetValNew05
objReg.GetStringValue HKLM, strInstallSource, strNValue06, strRetValNew06
objReg.GetStringValue HKLM, strInstallSource, strNValue07, strRetValNew07
objReg.GetStringValue HKLM, strInstallSource, strNValue10, strRetValNew10
objReg.GetStringValue HKLM, strInstallSource, strNValue12, strRetValNew12
objReg.GetStringValue HKLM, strInstallSource, strNValue13, strRetValNew13
objReg.GetStringValue HKLM, strInstallSource2, strNValue11, strRetValNew11
	
'' Pull the Product Code from the Uninstall String
strProdCode = strRetValNew07
	ProdCodeLen = Len(strProdCode)
	ProdCodeLen = ProdCodeLen - 14
strRetValNew08 = Right(strProdCode, ProdCodeLen)
	
'' Pull out path from LastUsedSource
strGetRealPath = strRetValue02
	GetRealPath = Len(strRetValue02)
strRealPath = Mid(strRetValue02, 5, GetRealPath)
	
'' Identifie the string in the ProductName
If instr(1, strRetValue00, strSQLName, 1) Then
'' Start the log output
	txtFile.writeline "================================================================================"
	txtFile.writeline "PRODUCT NAME : " & strRetValue00
	txtFile.writeline "================================================================================"
	txtFile.writeline " Product Code: " & strRetValNew08
	txtFile.writeline " Version	 : " & strRetValNew05
	txtFile.writeline " Most Current Install Date: " & strRetValNew06
	txtFile.writeline " Target Install Location: " & strRetValNew13
	txtFile.writeline " Registry Path: "
	txtFile.writeline " HKEY_CLASSES_ROOT\" & strKeyPath02
	txtFile.writeline "	 Package	: " & strRetValue01
	txtFile.writeline " Install Source: " & strRetValue10
	txtFile.writeline " LastUsedSource: " & strRetValue02
'' txtFile.writeline "Does this file on this path exist? " & strRetValNew02 & "\" & strRetValue01
	If fso.fileexists(strRetValNew02 & "\" & strRetValue01) Then
	txtFile.writeline " "
		txtFile.writeline "	" & strRetValue01 & " exists on the LastUsedSource path, no actions needed."
	Else
		txtFile.writeline " "
		txtFile.writeline " !!!! " & strRetValue01 & " DOES NOT exist on the path in the path " & strRealPath & " !!!!"
		txtFile.writeline " "
		txtFile.writeline " Action needed, re-establish the path to " & strRealPath
'' Placeholder for altering the LastUsedSource by adding source location and Forcing search of list
''		If strNewSource <> "" Then
''		txtFile.writeline "	 New Install Source Path Added: " & strNewSource
''		wiInstaller.AddSource strRetValNew08, "", strNewSource
''		Else
''		If strNewRTMSource <> "" Then
''		wiInstaller.AddSource strRetValNew08, "", strNewRTMSource
''		txtFile.writeline "	 Forcing SourceList Resolution For: " & strRetValNew08
''		wiInstaller.ForceSourceListResolution strRetValNew08, ""
''		End If
''		End If
	End If
		txtFile.writeline " "
		txtFile.writeline "Installer Cache File: " & strRetValNew04
	If fso.fileexists(strRetValNew04) Then
		txtFile.writeline " "
		txtFile.writeline "	Package exists in the Installer cache, no actions needed."
		txtFile.writeline "	Any missing packages will update automatically if needed assuming that"
		txtFile.writeline "	the LastUsedSource exists."
		txtFile.writeline " "
		txtFile.writeline "	Should you get errors about " & strRetValNew04 & " or " & strRealPath & strRetValue01 & " then you"
		txtFile.writeline "	may need to manually copy the file, if file exists replace the problem file, "
		txtFile.writeline "	Copy and paste the following command line into an administrative command prompt:"
		txtFile.writeline " "
		txtFile.writeline "	 Copy " & chr(34) & strRealPath & strRetValue01 & chr(34) & " " &strRetValNew04
		txtFile.writeline " "
	ElseIf fso.fileexists(strRetValNew02 & "\" & strRetValue01) Then
				fso.CopyFile strRetValNew02 & "\" & strRetValue01, strRetValNew04
		If fso.fileexists(strRetValNew04) Then
			txtFile.writeline " "
			txtFile.writeline "	 Missing cache file replaced by copying " & strRealPath & strRetValue01 & " to " & strRetValNew04
			txtFile.writeline "	 Previously missing package " & strRetValNew04 & " now exists in the Installer cache."
			txtFile.writeline " "
		End If
	Else
		txtFile.writeline " "
		txtFile.writeline " !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
		txtFile.writeline " !!!! " & strRetValNew04 & " DOES NOT exist in the Installer cache. !!!!"
		txtFile.writeline " !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
		txtFile.writeline " "
		txtFile.writeline "	 Action needed, recreate or re-establish path to the directory:"
		txtFile.writeline "	 " & strRealPath & "then rerun this script to update installer cache and results"
		txtFile.writeline "	 The path on the line above must exist at the root location to resolve"
		txtFile.writeline "	 this problem with your msi/msp file not being found or corrupted,"
		txtFile.writeline "	 In some cases you may need to manually copy the missing file or manually"
		txtFile.writeline "	 replace the problem file overwriting it is exist: "
		txtFile.writeline " "
		txtFile.writeline "	 Copy " & chr(34) & strRealPath & strRetValue01 & chr(34) & " " &strRetValNew04
		txtFile.writeline " "
		txtFile.writeline "	 Replace the existing file if prompted to do so."
		txtFile.writeline " "
	End If
	txtFile.writeline " "
	txtFile.writeline strRetValue00 & " Patches Installed "
	txtFile.writeline "--------------------------------------------------------------------------------"
	
	err.clear
	objReg.EnumKey HKLM, strInstallSource2, arrSubKeys2
	uUpperBounds = UBound(arrSubKeys2,1)
		If err.number = 0 Then
		For Each strSubKey2 in arrSubKeys2
	''	WScript.echo "value = " & strSubKey2
	
strKeyPath04 = "Installer\Patches\" & strSubKey2 & "\SourceList"
	
		objReg.GetDWORDValue HKLM, strInstallSource2 & "\" & strSubKey2 & "\", strNValue16, strRetValue16
		objReg.GetStringValue HKCR, strKeyPath04, strNValue15, strRetValue15a
		objReg.GetStringValue HKCR, strKeyPath04, strNValue14, strRetValue14a
		objReg.GetStringValue HKCR, strKeyPath02, strNValue15, strRetValue15b
		objReg.GetStringValue HKCR, strKeyPath02, strNValue14, strRetValue14b
		objReg.GetStringValue HKLM, strInstallSource2 & "\" & strSubKey2 & "\", strNValue17, strRetValue17
		objReg.GetStringValue HKLM, strInstallSource2 & "\" & strSubKey2 & "\", strNValue18, strRetValue18
		objReg.GetStringValue HKLM, strInstallSource2 & "\" & strSubKey2 & "\", strNValue13, strRetValue13a
		objReg.GetStringValue HKLM, strInstallSource3 & "\" & strSubKey2 & "\", strNValue04, strRetValue04a
	
'' Pull the URL from the MoreInfoURL String
strMoreInfoURL = strRetValue13a
	MoreInfoURLLen = Len(strMoreInfoURL)
strRetValue13b = Right(strMoreInfoURL, 42)
	
'' Pull the URL from the LastUsedPath String
strLastUsedPath = strRetValue15a
	LastUsedPathLen = Len(strLastUsedPath)
	''LastUsedPathLen = LastUsedPathLen - 15
strRetValue15c = Mid(strLastUsedPath, 5)
	
		txtFile.writeline " Display Name:	" & strRetValue17
		txtFile.writeline " KB Article URL: " & strRetValue13b
		txtFile.writeline " Install Date:	" & strRetValue18
				txtFile.writeline " Uninstallable: " & strRetValue16
		txtfile.writeline " Patch Details: "
		txtFile.writeline " HKEY_CLASSES_ROOT\Installer\Patches\" & strSubKey2
				txtFile.writeline " PackageName: " & strRetValue14a
'' Determine if someone has modified the Uninstallable state from 0 to 1 allowing possible unexpected uninstalls
				txtFile.writeline "	Patch LastUsedSource: " & strRetValue15a
				txtFile.writeline " Installer Cache File Path:	 " & strRetValue04a
		txtFile.writeline "	 Per " & strInstallSource3 & "\" & strSubKey2 & "\" & strNValue04
				mspFileName = (strRetValue15c & strRetValue14a)
		If strRetValue14a <> "" Then
		If fso.fileexists(strRetValue04a) Then
		txtFile.writeline " "
		txtFile.writeline "	Package exists in the Installer cache, no actions needed."
		txtFile.writeline "	Package will update automatically if needed assuming that"
		txtFile.writeline "	the LastUsedSource exists."
		txtFile.writeline " "
		txtFile.writeline "	Should you get errors about " & strRetValue04a & " or " & strRetValue15c & strRetValue14a & " then you"
		txtFile.writeline "	may need to manually copy missing files, if file exists replace the problem file, "
		txtFile.writeline "	Copy and paste the following command line into an administrative command prompt."
		txtFile.writeline " "
		txtFile.writeline "	 Copy " & chr(34) & strRetValue15c & strRetValue14a & chr(34) & " " & strRetValue04a
		txtFile.writeline " "
		ElseIf fso.fileexists(mspFileName) Then
				fso.CopyFile mspFileName, strRetValue04a
			If fso.fileexists(strRetValue04a) Then
			txtFile.writeline " "
			txtFile.writeline " Missing cache file replaced by copying " & strRetValue15c & strRetValue14a & " to " & strRetValue04a
			txtFile.writeline " Previously missing package " & strRetValNew04 & " now exists in the Installer cache."
			txtFile.writeline " "
			End If
''		End If
		Else
		txtFile.writeline " "
		txtFile.writeline "!!!! " & strRetValue04a & " package DOES NOT exist in the Installer cache. !!!!"
		txtFile.writeline " "
		txtFile.writeline "	 Action needed, recreate or re-establish path to the directory:"
		txtFile.writeline "	 " & strRetValue15c & " then rerun this script to update installer cache and results"
		txtFile.writeline "	 The path on the line above must exist at the root location to resolve"
		txtFile.writeline "	 this problem with your msi/msp file not being found or corrupted,"
		txtFile.writeline "	 In some cases you may need to manually copy missing files or manually"
		txtFile.writeline "	 replace the problem file, "
		txtFile.writeline " "
		txtFile.writeline "	 Copy " & chr(34) & strRetValue15c & strRetValue14a & chr(34) & " " & strRetValue04a
		txtFile.writeline " "
		txtFile.writeline "	 Replace the existing file if prompted to do so."
		txtFile.writeline " "
		txtFile.writeline "	 Use the following URL to assist with downloading the patch:"
		txtFile.writeline "	 " & strRetValue13b
		txtFile.writeline " "
		txtFile.writeline " "
		End If
		Else
		txtFile.writeline " "
		End If
		next
		Else
		txtfile.writeline " "
		txtfile.Writeline " No Patches Found"
		txtfile.writeline " "
	End If
	
	End If
	
	
Next
txtFile.Close
Set txtFile = Nothing
Set fso = Nothing
' | Set-Content $Vbs_Check_File
Write-Host "VBS file created."

#Creating a name of the verification file
Write-Host "`n`tCreating filename for the results."
$Verify_File = $Target_Folder+'SQLCheckResults_'+(Get-Date -Format "yyyyMMdd_HHmm")+'.txt'

#Invoke VBS file for checks
Write-Host "`tInvoking VBS file for the checks."
Cscript.exe $Vbs_Check_File $Verify_File | Out-Null
Write-Host "Report created: "$Verify_File

$Verification = Get-Content -Path $Verify_File -Raw
$Missing_Files = $Target_Folder+'MSIFillesMissing_'+(Get-Date -Format "yyyyMMdd_HHmm")+'.txt'

#Create a temp file to check installer cache
If((Test-Path $Missing_Files) -eq $true){Remove-Item -Path $Missing_Files -Force}
New-Item -Path $Missing_Files -ItemType "file" | Out-Null
#Count files missing both from cache and Last Used Source
$Missing_Files_Cache = ([regex]::Matches($Verification, "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")).count
If($Missing_Files_Cache -ne 0) {
	$Missing_Files_Cache = $Missing_Files_Cache/2
}

#Count files missing from Last Used Source
$Missing_Files_No = ([regex]::Matches($Verification, "!!!! " )).count - $Missing_Files_Cache
If($Missing_Files_No -eq 0) {
	Write-Host "`nNo .msi file is missing from the Last Used Source. Installer cache verification is successful."
}
Else{
	Write-Host "`n`t" $Missing_Files_No " .msi file(s) missing from the Last Used Source."
	Write-Host "`tAttempting to verify if they are in Installer cache."
}

$Verification = $Verification -Replace('PRODUCT NAME','MYCOOLSEPARATOR PRODUCT NAME')
$Verification = $Verification -Replace('Display Name','MYCOOLSEPARATOR Display Name')

$Verification2 = $Verification -split('MYCOOLSEPARATOR')

$i = 0
Foreach($String in $Verification2){
	If($String.IndexOf('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!') -ge 1) {
		If($String.IndexOf('PRODUCT NAME') -ge 1 ){
			$Product_Name = $String.Substring($String.IndexOf('PRODUCT NAME')+17,$String.IndexOf('=====')-18-$String.IndexOf('PRODUCT NAME'))
			
			$Package_Name = $String.Substring($String.IndexOf('Package	: ')+13,$String.IndexOf('.ms')+1-$String.IndexOf('Package	: ')-10)
			
			$Package_Name = $String.Substring($String.IndexOf('LastUsedSource:')+20,$String.IndexOf('!!!! ')-26-$String.IndexOf('LastUsedSource:'))
			
			$Cache_File = $String.Substring($String.IndexOf('Installer Cache File: ')+22,$String.IndexOf('.ms',$String.IndexOf('Installer Cache File: ')+1)+1-$String.IndexOf('Installer Cache File: ')-19)
			
			$Copy_Cmd = $String.Substring($String.IndexOf('Copy '),$String.IndexOf('Replace')-$String.IndexOf('Copy ')-9)
			
			$Missing_File = " Missing component of: `t $Product_Name
`n Package name: `t`t $Package_Name
`n Last used source: `t $Last_Used
`n Cache path: `t`t $Cache_File
`n Use following command after recreating Last Used Path:
`n`t $Copy_Cmd `n
"
			Add-Content -Path $Missing_Files -Value $Missing_File
			
			$i++
		}
		If($String.IndexOf('Display Name') -ge 1 ){
			$Product_Name = $String.Substring($String.IndexOf('Display Name')+17,$String.IndexOf('=====')-18-$String.IndexOf('Display Name'))
			
			$Package_Name = $String.Substring($String.IndexOf('Package	: ')+13,$String.IndexOf('.ms')+1-$String.IndexOf('Package	: ')-10)
			
			$Last_Used = $String.Substring($String.IndexOf('LastUsedSource:')+20,$String.IndexOf('!!!! ')-26-$String.IndexOf('LastUsedSource:'))
			
			$Cache_File = $String.Substring($String.IndexOf('Installer Cache File: ')+22,$String.IndexOf('.ms',$String.IndexOf('Installer Cache File: ')+1)+1-$String.IndexOf('Installer Cache File: ')-19)
			
			$Copy_Cmd = $String.Substring($String.IndexOf('Copy '),$String.IndexOf('Replace')-$String.IndexOf('Copy ')-9)
			
			$Missing_File = " Missing component of: `t $Product_Name
`n Package name: `t`t $Package_Name
`n Last used source: `t $Last_Used
`n Cache path: `t`t $Cache_File
`n Use following command after recreating Last Used Path:
`n`t $Copy_Cmd `n
"
			Add-Content -Path $Missing_Files -Value $Missing_File
			
			$i++
		}
	}
}

#Get value from temp file and remove it
If($i -gt 0) {
	Write-Host $i " file(s) have been found to be missing from installer cache as well. You need to correct it manually."
}
Else{
	Write-Host $i " file(s) have been found to be missing from installer cache as well."
}
$Save = Read-Host "`nDo you wish to keep the file with exact files missing? [yes/no]"
If(($Save -eq "yes") -or ($Save -eq "y")) {
Write-Host $Missing_Files " has been saved."
}
Else{
Remove-Item $Missing_Files -Force
}
$Save = Read-Host "`nDo you wish to keep the file with the complete report? [yes/no]"
If(($Save -eq "yes") -or ($Save -eq "y")) {
Write-Host $Verify_File " has been saved."
}
Else{
Remove-Item $Verify_File -Force
}
Remove-Item $Vbs_Check_File -Force
Write-Host "`nRemoved FindSQLinstalls.vbs"

<# PART 02 - Check Service Accounts for all instances #>

#List all instances on the host
Write-Host "`nFinding all instances running on the host."

$Sql_Instances = (Get-WmiObject win32_service | Where-Object {$_.Name -like 'MSSQL*' -and $_.Name -notlike 'MSSQLFDLauncher*'}) | Select-Object -ExpandProperty Name

#Create a loop for each instance
Foreach($Instance in $Sql_Instances){
	$Svc_Acc = (Get-WmiObject win32_service | Where-Object {$_.Name -like $Instance}) | Select-Object -ExpandProperty StartName
	$Sql_Name = (Get-WmiObject win32_service | Where-Object {$_.Name -like $Instance}) | Select-Object -ExpandProperty DisplayName

	Write-Host "`n`t$Sql_Name is running under " $Svc_Acc
	#Checking if Svc Account is LocalSystem
	If($Svc_Acc.ToUpper() -like 'LOCALSYSTEM*'){
		Write-Host "Service account is a local account - no checks needed. Consider changing it in the future."
	}
	#Checking if Svc Account is a virtual account
	Elseif($Svc_Acc.ToUpper() -like 'NT SERVICE*'){
		Write-Host "Service account is a virtual account - no checks needed."
	}
	#Checking if Svc Account is an MSA account
	Elseif($Svc_Acc -like '*$'){
		Write-Host "Service account is an MSA account - no checks needed."
	}
	#Checking if Svc Account is an AD account
	Else{
		If(!(Get-Module -name ActiveDirectory) -eq $true) {
			Write-Host "`tNo ActiveDirectory module for PowerShell installed on the host. Attempting to complete the checks with net user."
				$Svc_Acc = $Svc_Acc.Substring($Svc_Acc.Length -($Svc_Acc.Length-$Svc_Acc.IndexOf("\")-1))
				$Ad_Status = net user $Svc_Acc /DOMAIN | Select-String "Account active"
				$Ad_Pwd_Exp = net user $Svc_Acc /DOMAIN | Select-String "Password expires"
				If($Ad_Pwd_Exp -notlike '*Never*') {
					$Ad_Pwd_Exp2=[datetime]($Ad_Pwd_Exp.Line.Substring(29,20))
					$Ad_Pwd_Exp3 = Get-Date $Ad_Pwd_Exp2 -format "yyyy-MM-dd HH-mm-ss"
					$Today = Get-Date -format "yyyy-MM-dd HH-mm-ss"
				}
			If(($Ad_Status -notlike '*Yes*') -or (($Ad_Pwd_Exp -notlike '*Never*') -and ($Ad_Pwd_Exp3 -le $Today))){
				Write-Error "Service account for the SQL instance is AD account and is either locked out or password is expired. Consider fixing service account first." -ErrorAction Continue
			}
			Write-Host "Service account is an AD account - no issues with account found."
		}
		Else{
			$Ad_Status = Get-AdUser -Identity $Svc_Acc | Select-Object -ExpandProperty Enabled
			$Ad_Pwd_Exp = Get-AdUser -Identity $Svc_Acc | Select-Object -ExpandProperty PasswordExpired
			If(($Ad_Status -ne "True") -or ($Ad_Pwd_Exp -eq "True")){
				Write-Error "Service account for the SQL instance is AD account and is either locked out or password is expired. Consider fixing service account first." -ErrorAction Continue
			}
			Write-Host "Service account is an AD account - no issues with account found.."
		}
	}
}

<# PART 03 - Checking size of system databases #>

Write-Host "`n`tCalculating size of system databases."
$Sql_Instances = (Get-WmiObject win32_service | Where-Object {$_.Name -like 'MSSQL*' -and $_.Name -notlike '*FDLauncher*'}) | Select-Object -ExpandProperty Name

#Create a loop for each instance
Foreach($Instance in $Sql_Instances){
	If($Instance -eq 'MSSQLSERVER'){
		$Sql_Name = (Get-WmiObject win32_service | Where-Object {$_.Name -like $Instance -and $_.Name -notlike '*FDLauncher*'}) | Select-Object -ExpandProperty DisplayName
	}
	Else{
		$Sql_Name = (Get-WmiObject win32_service | Where-Object {$_.Name -like $Instance -and $_.Name -notlike '*FDLauncher*'}) | Select-Object -ExpandProperty DisplayName
		$Begin3 = $Instance.IndexOf('$')+1
		$Len3 = $Instance.Length-$Begin3
		$Instance = $Instance.Substring($Begin3,$Len3)
	}
	Write-Host "`n`tCalculating for $Instance"
	#Get instance ID from Registry - if ID is missing, exit and print an error
	$Instance_Id = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL').$Instance
	If(!$Instance_Id){
		Write-Error ("Instance ID not found in the registry") -ErrorAction Stop
	}
	#Get instance details from Registry
	$Instance_Bin = (Get-ItemProperty -Path ("HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\" + $Instance_Id + "\Setup" )).SqlBinRoot
	$Instance_Data = (Get-ItemProperty -Path ("HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\" + $Instance_Id + "\Setup" )).SqlDataRoot
	#Check if instance is clustered
	If($null -ne (Get-ClusterResource | Where-Object {$_.Name -like ("*("+ $Instance + ")*") -and $_.ResourceType -eq "SQL Server" })){
		Write-Host "`t$Instance is a clustered instance. Checking if the current host is the owner node of this instance."
	#Check if script is being run on owner node of a clustered instance
		If(((Get-ClusterResource | Where-Object {$_.Name -like ("*("+ $Instance + ")*") -and $_.ResourceType -eq "SQL Server" }).OwnerNode.name) -eq $env:computername){
			Write-Host "`tThis is owner node. Proceed with verification of the size of system DBs."
		}
	#If it's not owner node, adjust the filepath to the owner node
		Else{
			Write-Host "`tThis is not an owner node. Adjusting the filepaths of system DBs."
			$Curr_Owner = (Get-ClusterResource | Where-Object {$_.Name -like ("*("+ $Instance + ")*") -and $_.ResourceType -eq "SQL Server" }).OwnerNode.name
			$Instance_Bin = '\\'+$Curr_Owner+'\'+$Instance_Bin.Replace(':\', '$\')
			$Instance_Data = '\\'+$Curr_Owner+'\'+$Instance_Data.Replace(':\', '$\')
		}
	}
	#Get size of systemDBs for all instances
	$Sys_Db01 = (Get-ChildItem -Path $Instance_Data -Include master.*,model.*,msdb.*,model_msdb.*,model_replica.* -Recurse -Force | Measure-Object -Sum Length).Sum
	$Sys_Db02 = (Get-ChildItem -Path $Instance_Bin -Include mssqlsystemresource.* -Recurse -Force | Measure-Object -Sum Length).Sum
	$Sys_Db_Total = ([math]::Round(($Sys_Db01 + $Sys_Db02) / (1024*1024*1024),2))
	If($Sys_Db_Total -ge 1){
		Write-Host "`nSystemDBs of" $Sql_Name "have a total size of" $Sys_Db_Total "GB - this can lead to a long time of zipping systemDBs, if you use zip_sys_dbs.ps1."
	}
	Else{
		Write-Host "`nSystemDBs of" $Sql_Name "have a total size of" $Sys_Db_Total "GB - this shouldn't lead to a long time of zipping systemDBs, if you use zip_sys_dbs.ps1."
	}
}


<# PART 04 - Checking states of databases for additional features #>

$Sql_Instances = (Get-WmiObject win32_service | Where-Object {$_.Name -like 'MSSQL*' -and $_.Name -notlike 'MSSQLFDLauncher*'}) | Select-Object -ExpandProperty Name
#Create an array
$Server_Instance_List = @()
[System.Collections.ArrayList]$Server_Instance_List = $Server_Instance_List
#Populate an array
Foreach($Instance in $Sql_Instances){
	If($Instance -ne 'MSSQLSERVER'){
		$Instance = $Instance.Replace('MSSQL$','')
	}
	#Get instance_id
	$Instance_Id = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL').$Instance
	$Cluster_Reg = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\'+$Instance_Id+'\Cluster'
	#Get cluster name for a clustered instance
	If((Test-Path -Path $Cluster_Reg) -eq $true){
		$Server_Name = (Get-ItemProperty -Path $Cluster_Reg).ClusterName
		$Server_Instance = $Server_Name+'\'+$Instance
		#Add instance to an array
		$Server_Instance_List.Add($Server_Instance) | Out-Null
	}
	#Get computername for non-clustered instance
	Else{
		$Server_Name = $env:computername
		$Server_Instance = $Server_Name+'\'+$Instance
		#Add instance to an array
		$Server_Instance_List.Add($Server_Instance) | Out-Null
	}
}
#check if there is any SSRS/SSIS
Write-Host "`n`tChecking if there are any SSRS or SSIS on the server".
If(((Test-Path 'HKLM:\SYSTEM\ControlSet001\Services\MsDtsServe*') -eq $true) -or ((Test-Path 'HKLM:\SYSTEM\ControlSet001\Services\ReportServe*') -eq $true)){
	Write-Host "`n`tFeatures found. Querying all instances on the host in order to verify in any SSIS/SSRS databases are not ONLINE."
	Foreach($Server_Instance in $Server_Instance_List){
		#Query each server in array
		$Ssis_Db_Tables = Invoke-Sqlcmd -ServerInstance $Server_Instance -Query "IF EXISTS (SELECT [name] FROM sys.databases WHERE [name] = 'SSISDB' AND state_desc <> 'ONLINE') BEGIN SELECT @@SERVERNAME AS Instance, [name] AS [database], [state_desc] AS [state] FROM sys.databases WHERE [name] = 'SSIDB' END" -As DataTables	
		$Report_Tables = Invoke-Sqlcmd -ServerInstance $Server_Instance -Query "IF EXISTS (SELECT [name] FROM sys.databases WHERE [name] LIKE 'ReportServ%' AND state_desc <> 'ONLINE') BEGIN SELECT @@SERVERNAME AS Instance, [name] AS [database], [state_desc] AS [state] FROM sys.databases WHERE [name] LIKE 'ReportServ%' END" -As DataTables	
	}
	#Clear an array
	$Server_Instance_List = $null

	#Verify if there's any non-online SSISDB
	If($null -eq $Ssis_Db_Tables){
		Write-Host "No SSISDB databases found on any instance."
	}
	Else{
		Write-Host "Following SSISDB databases which are not in ONLINE state have been found. If the instance participates in LogShipping or Mirroring, please make sure that before the upgrade this database will be updateable on this instance."
		$Ssis_Db_Tables
	}

	#Verify if there's any non-online ReportServer db
	If($null -eq $Report_Tables){
		Write-Host "No ReportServer databases found on any instance."
	}
	Else{
		Write-Host "Following ReportServer databases which are not in ONLINE state have been found. If the instance participates in LogShipping or Mirroring, please make sure that before the upgrade these databases will be updateable on this instance."
		$Report_Tables
	}
}
Else{
	Write-Host "No such features found."
}

Write-Host "Checks for features' based databases completed."

<# PART 05 - Checking registry entries for default paths #>

Write-Host "`n`tChecking registry for default data, log and backup paths"

$Sql_Instances = (Get-WmiObject win32_service | Where-Object {$_.Name -like 'MSSQL*' -and $_.Name -notlike 'MSSQLFDLauncher*'}) | Select-Object -ExpandProperty Name
Foreach($Instance in $Sql_Instances){
	If($Instance -ne 'MSSQLSERVER'){
		$Instance = $Instance.Replace('MSSQL$','')
	}
	#Get instance id
	$Instance_Id = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL').$Instance
	Write-Host "`n`tChecking values for $Instance"
	#Get backup path
	$Def_Back_Reg = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\'+$Instance_Id+'\MSSQLServer'
	If((Test-RegistryValue -Path $Def_Back_Reg -Value 'BackupDirectory') -eq $false){
		$Def_Back_Path = $null
		Write-Host "`tCannot find default backup path at $Def_Back_Reg\BackupDirectory"
	}
	Else{
		$Def_Back_Path = (Get-ItemProperty -Path ($Def_Back_Reg)).BackupDirectory
		Write-Host "`tFound default backup path: $Def_Back_Path"
	}
	#Get system DBs path
	$Def_System_Reg = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\'+$Instance_Id+'\Setup'
	If((Test-RegistryValue -Path $Def_System_Reg -Value 'SQLDataRoot') -eq $false){
		$Def_System_Path = $null
		Write-Host "`tCannot find system DBs path at $Def_System_Reg\SQLDataRoot"
	}
	Else{
		$Def_System_Path = (Get-ItemProperty -Path ($Def_System_Reg)).SQLDataRoot
		Write-Host "`tFound default system DBs path: $Def_System_Path"
	}
	#Get default data path
	$Def_Data_Reg = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\'+$Instance_Id+'\MSSQLServer'
	If((Test-RegistryValue -Path $Def_Data_Reg -Value 'DefaultData') -eq $false){
		$Def_Data_Path = $null
		Write-Host "`tCannot find default data path at $Def_Data_Reg\DefaultData"
	}
	Else{
		$Def_Data_Path = (Get-ItemProperty -Path ($Def_Data_Reg)).Defaultdata
		Write-Host "`tFound default data path: $Def_Data_Path"
	}

	#Check default log path
	$Def_Log_Reg = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\'+$Instance_Id+'\MSSQLServer'
	If((Test-RegistryValue -Path $Def_Log_Reg -Value 'DefaultLog') -eq $false){
		$Def_Log_Path = $null
		Write-Host "`tCannot find default log path at $Def_Log_Reg\DefaultLog"
	}
	Else{
		$Def_Log_Path = (Get-ItemProperty -Path ($Def_Log_Reg)).DefaultLog
		Write-Host "`tFound default log path: $Def_Data_Path"
	}

	#Check if instance is clustered
	If($null -ne (Get-ClusterResource | Where-Object {$_.Name -like ("*("+ $Instance + ")*") -and $_.ResourceType -eq "SQL Server" })){
		Write-Host "`t$Instance is a clustered instance. Checking if the current host is the owner node of this instance."
	#Check if script is being run on owner node of a clustered instance
		If(((Get-ClusterResource | Where-Object {$_.Name -like ("*("+ $Instance + ")*") -and $_.ResourceType -eq "SQL Server" }).OwnerNode.name) -eq $env:computername){
			Write-Host "`tThis is owner node. Proceed with verification of the default paths."
		}
	#If it's not owner node, adjust the filepath to the owner node
		Else{
			Write-Host "`tThis is not an owner node. Adjusting the filepaths to use the name of the current owner."
			$Curr_Owner = (Get-ClusterResource | Where-Object {$_.Name -like ("*("+ $Instance + ")*") -and $_.ResourceType -eq "SQL Server" }).OwnerNode.name
			If($null -ne $Def_Back_Path){
				$Def_Back_Path = '\\'+$Curr_Owner+'\'+$Def_Back_Path.Replace(':\', '$\')
			}
			If($null -ne $Def_System_Path){
				$Def_System_Path = '\\'+$Curr_Owner+'\'+$Def_System_Path.Replace(':\', '$\')
			}
			If($null -ne $Def_Data_Path){
				$Def_Data_Path = '\\'+$Curr_Owner+'\'+$Def_Data_Path.Replace(':\', '$\')
			}
			If($null -ne $Def_Log_Path){
				$Def_Log_Path = '\\'+$Curr_Owner+'\'+$Def_Log_Path.Replace(':\', '$\')
			}
		}
	}

	#Verify default backup path
	If($null -eq $Def_Back_Path){
		Write-Host "Default backup path has not been found in registry and has not been verified on the host."
	}
	Else{
		If((Test-Path -Path $Def_Back_Path) -eq $true){
			Write-Host "Verified that default backup path exists on the host."
		}
		Else{
			Write-Host "Cannot find default backup path on the host. If you encounter issues during upgrade please update value of registry key $Def_Back_Reg\BackupDirectory"
		}
	}
	#Verify system DBs default path
	If($null -eq $Def_System_Path){
		Write-Host "Default system DBs path has not been found in registry and has not been verified on the host."
	}
	Else{
		If((Test-Path -Path $Def_System_Path) -eq $true){
			Write-Host "Verified that default system DBs path exists on the host."
			If(((Test-Path -Path ($Def_System_Path+'\Data\master.mdf')) -ne $true) -or ((Test-Path -Path ($Def_System_Path+'\Data\mastlog.ldf')) -ne $true)){
				Write-Host "Either mdf or ldf of master database is not located in the default systemDB path. You need to correct this."
			}
			Else{
				Write-Host "Both mdf and ldf of master databases is located in the default systemDB path."
			}
			If(((Test-Path -Path ($Def_System_Path+'\Data\model.mdf')) -ne $true) -or ((Test-Path -Path ($Def_System_Path+'\Data\modellog.ldf')) -ne $true)){
				Write-Host "Either mdf or ldf of model database is not located in the default systemDB path. You need to correct this."
			}
			Else{
				Write-Host "Both mdf and ldf of model databases is located in the default systemDB path."
			}
			If(((Test-Path -Path ($Def_System_Path+'\Data\MSDBData.mdf')) -ne $true) -or ((Test-Path -Path ($Def_System_Path+'\Data\MSDBLog.ldf')) -ne $true)){
				Write-Host "Either mdf or ldf of msdb database is not located in the default systemDB path. You need to correct this."
			}
			Else{
				Write-Host "Both mdf and ldf of msdb databases is located in the default systemDB path."
			}
		}
		Else{
			Write-Host "Cannot find default system DBs path on the host. If you encounter issues during upgrade please update value of registry key $Def_System_Reg\SQLDataRoot"
		}
	}
	#Verify default data path
	If($null -eq $Def_Data_Path){
		Write-Host "Default data path has not been found in registry and has not been verified on the host."
	}
	Else{
		If((Test-Path -Path $Def_Data_Path) -eq $true){
			Write-Host "Verified that default data path exists on the host."
		}
		Else{
			Write-Host "Cannot find default data path on the host. If you encounter issues during upgrade please update value of registry key $Def_Data_Reg\DefaultData"
		}
	}
	#Verify default log path
	If($null -eq $Def_Log_Path){
		Write-Host "Default log path has not been found in registry and has not been verified on the host."
	}
	Else{
		If((Test-Path -Path $Def_Log_Path) -eq $true){
			Write-Host "Verified that default log path exists on the host."
		}
		Else{
			Write-Host "Cannot find default log path on the host. If you encounter issues during upgrade please update value of registry key $Def_Log_Reg\DefaultLog"
		}
	}
}

<# PART 06 - Check drive free space #>

Write-Host "`n`tGetting free space for the drives used most often for installations (installation media, binaries, etc.)."
$Drives =@('C:','D:','E:')
Get-WmiObject -Class Win32_LogicalDisk | Where-Object DeviceID -in $Drives | ForEach-Object { "`t`tDrive: "+$_.DeviceID+"`tFree Space: "+( [math]::Round( ($_.FreeSpace/1GB),2 ) )+" GB" }
Write-Host "If any of the drives has low disk space. Try to get rid of it in advance."

<# PART 07 - Check if you can expect a long reboot #>

$Datastore_Db = Get-Item C:\windows\softwaredistribution\datastore\datastore.edb | Select-Object -ExpandProperty Length
$Datastore_Db = ([math]::Round($Datastore_Db/(1024*1024),2))

If($Datastore_Db -ge 1024){
	Write-Host "`nDataStore has size of " $Datastore_Db " MB which can mean a long reboot. You can consider following commands to 'shrink' it. Use with caution and consult Windows team"
	Write-Host "`t`tNET STOP BITS"
	Write-Host "`t`tNET STOP WUAUSERV"
	Write-Host "`t`tesentutl.exe /k c:\Windows\SoftwareDistribution\DataStore\DataStore.edb"
	Write-Host "`t`tesentutl.exe /g c:\Windows\SoftwareDistribution\DataStore\DataStore.edb"
	Write-Host "`t`tesentutl.exe /d c:\Windows\SoftwareDistribution\DataStore\DataStore.edb"
	Write-Host "`t`tNET START BITS"
	Write-Host "`t`tNET START WUAUSERV"
}
Else{
	Write-Host "`nSize of DataStore is" $Datastore_Db "MB. This shouldn't lead to a long reboot "
}
#Find uptime of the server
$Boot = Get-WmiObject -Class win32_operatingsystem
$Uptime = [math]::Round(((get-date) - $Boot.ConvertToDateTime($Boot.LastBootUpTime)).TotalDays,0)
If($Uptime -ge 120){
	Write-Host "`nWindows server has been up for" $Uptime "days. This can lead to a long reboot."
}
Else{
	Write-Host "`nWindows server has been up for" $Uptime "days. This shouldn't pose a risk of a long reboot."
}

<# PART 08 - Check if there's any pending reboot #>
$Test1 = Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -ErrorAction Ignore
$Test2 = Get-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -ErrorAction Ignore
$Test3 = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name PendingFileRenameOperations -ErrorAction Ignore
$Test4 = Invoke-WmiMethod -Namespace "ROOT\ccm\ClientSDK" -Class CCM_ClientUtilities -Name DetermineIfRebootPending -ErrorAction Ignore | Select-Object -ExpandProperty RebootPending

If(($Test1 -eq $true) -or ($Test2 -eq $true) -or ($Test3 -eq $true) -or ($Test4 -eq $true)){
	Write-Host "`nPending reboot."
}
Else{
	Write-Host "`nNo pending reboot."
}


Write-Host "`nChecks completed." 
