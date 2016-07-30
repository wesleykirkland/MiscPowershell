#Script to auto disconnect know Isos's
#Written by Wesley Kirkland 11-19-14

#Add Powercli
Get-PSSnapin -Registered | Add-PSSnapin

#Connect to the vCenter Server
Connect-VIServer -Server $vcenter -WarningAction SilentlyContinue | Out-Null

#Generate Report of vms with attached SCCM iso's to say hey this will be disconnected, well its to late now that you have the report
$reportraw = Get-VM | Where-Object {($_.Name -notlike "*Template*") -and ($_.PowerState –eq “PoweredOn”)} | Get-CDDrive -ErrorAction SilentlyContinue | select Parent,IsoPath
$vmswithSCCMattached = $reportraw | Where-Object {$_.IsoPath -like "*SCCM*"}

#Find All Vms with connected iso's like *SCCM* and disconnect them.
$vmswithSCCMattached.Parent.Name | foreach {Get-VM -Name $_ | Get-CDDrive | Set-CDDrive -NoMedia -Confirm:$FALSE -ErrorAction SilentlyContinue}