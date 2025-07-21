#script from TMKP
Get-ClusterGroup | Where-Object {​$_.IsCoreGroup -eq $False}​ | ForEach-Object {​ $_.AutoFailbackType = 1 }​ #set automatic 'immediate' failback for all
