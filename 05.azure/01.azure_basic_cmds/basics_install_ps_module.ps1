#Check version of PS
    $PSVersionTable.PSVersion
 
#Check if Execution Policy is Remote Signed or Unrestricted
    Get-ExecutionPolicy -List
 
#Set it to RemoteSigned, if necessary
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
 
#Install module online if PowerShell is 7.0.6 LTS or 7.1.13 and higher
    Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
 
#Install module online if PowerShell is older
    #01. Update to Windows PowerShell 5.1. 
    #02. Install .NET Framework 4.7.2 or later.
    #03. Make sure you have the latest version of PowerShellGet. Run
    Install-Module -Name PowerShellGet -Force.
 
#Install module offline
    #01. Download the Azure PowerShell MSI. Keep in mind that the MSI installer only works for PowerShell 5.1 on Windows.
    #02. Download the modules to another location in your network and use that as an installation source. 
    #03. Save the module with Save-Module to a file share, or save it to another source and manually copy it to other machines.

