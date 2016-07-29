#Connect to vCenter
Connect-VIServer vcenter

$servers = Get-Cluster -Name "Cluster Name" | Get-VMHost #I would suggest doing a GC on this
[array]$Vlans = @('760')

foreach ($VMHost in $servers) {
    Write-Output "Working on $VMHost"

    #Get Virtual Switch on host
    $vSwitch0 = Get-VirtualSwitch -VMHost $VMHost -Standard -Name vSwitch0

    #Verify vSwitch 1 exists, if so make vlans
    if ($vSwitch0) {
        #Add VLAN
        foreach ($VlanTag in $Vlans) {
            New-VirtualPortGroup -Name ('VLAN' + $VlanTag) -VLanId $VlanTag -VirtualSwitch $vSwitch0
        }
    }
}