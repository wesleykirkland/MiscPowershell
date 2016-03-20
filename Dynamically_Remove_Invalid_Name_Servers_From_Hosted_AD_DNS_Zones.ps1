#This script will dynamically remove invalid name servers from AD Integrated DNS zones that are non-default zones
#The script will scan all AD Integrated DNS Zones and exclude default zones such as Trust Anchors and your msdsc zone(s), it will then attempt to resolve DNS for each entry.
#If DNS can not be resolved it will remove it from the nameservers entry array
#Author Wesley Kirkland
#Last Updated 03-19-2016

#PDCe
$DC = (Get-ADDomain).pdcemulator

#Get DNS Server Zones, excluding TrustAnchors and MSDSC zones
$DNSServerADIntegratedZones = Get-DnsServerZone -ComputerName $DC | Where-Object -Property IsDsIntegrated -EQ -Value $true | Where-Object -Property ZoneType -EQ -Value 'Primary' | Where-Object -Property ZoneName -NotMatch -Value "TrustAnchors|msdcs"

foreach ($Zone in $DNSServerADIntegratedZones) {
    $DNSZoneNameServers = Get-DnsServerResourceRecord -ZoneName $Zone.ZoneName -RRType Ns

    foreach ($NSEntry in $DNSZoneNameServers) {
        Write-Host $NSEntry.RecordData.NameServer
        Try {
            [System.Net.Dns]::GetHostEntry($NSEntry.RecordData.NameServer.Trim('.'))
        } Catch [System.Management.Automation.RuntimeException] {
           #Remove the record if we can not resolve DNS for it
           Write-Warning ("I wish to remove " + $NSEntry.RecordData.NameServer + " from the zone " + $Zone.ZoneName)
           Remove-DnsServerResourceRecord -ZoneName $zone.ZoneName -ComputerName $DC -RRType Ns -Name "@" -RecordData $NSEntry.RecordData.NameServer -Confirm:$false
        }
    }
}
