<# Created by Camilla Mo
Source: mostechtips.com/how-to-use-powershell-to-check-net-framework-version/
Modified by Mateusz Wierzbowski
Date of modification: 2022/12/05
Aim: Get overview of .NetFramework versions installed #>
 
Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -Recurse | Get-ItemProperty -Name Version -ErrorAction SilentlyContinue | 
	Where-Object { $_.PSChildName -Match '^(?!S)\p{L}'} | Format-Table @{Name='.NetComponent';Expression={$_.PSChildName}},Version
