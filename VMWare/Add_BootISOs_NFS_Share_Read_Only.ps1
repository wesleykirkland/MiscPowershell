Get-PSSnapin -Registered | Add-PSSnapin

Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Scope Session -Confirm:$false #Set default certification acction
Connect-VIServer vcenter #Connect to vCenter

#WildCard Clusters, Clusters to add to
$Clusters = @('*Cluster1*','*Cluster2*','*Ora*')

#Foreach around each cluster
foreach ($Cluster in $Clusters) {
    #Get each Host
    $VMHosts = Get-Cluster -Name $Cluster | Get-VMHost
    
    #Foreach around each host
    foreach ($VMHost in $VMHosts) {
        $VMHostDatastores = $VMHost | Get-Datastore

        #If BootISOs does not exist then add it
        if (!($VMHostDatastores.Name -contains 'BootISOs')) {
        $VMHost | New-Datastore -Name 'BootISOs' -NfsHost 'SCCMDP1.domain.com' -Path '/BootISOs' -ReadOnly
        }
    }
}