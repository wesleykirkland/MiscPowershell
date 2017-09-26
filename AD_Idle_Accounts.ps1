#Requires
#Requires -modules ActiveDirectory
#Requires -version 4.0

[System.Collections.ArrayList]$IgnoredADUsers = @()
#Build AD trust samaccountnames to filter out
Get-ADTrust -Filter * -Properties flatName | Select-Object @{Name='TrustSamaccountname';Expression={$($PSItem.flatName + '$')}} | Select-Object -ExpandProperty TrustSamaccountname | foreach {
    Try {
        $IgnoredADUsers.Add($PSItem) | Out-Null #Supress the output to the console
    } Catch {
        Write-Error "Unable to add $PSItem to IgnoredADUsers"
    }
}

#Add the static Admin SID
$DefaultAdministratorSID = (Get-ADDomain).domainsid.value + '-500'
Try {
    $IgnoredADUsers.Add($(Get-ADUser -Filter {(SID -eq $DefaultAdministratorSID)}).samaccountname) | Out-Null #Supress the output to the console
} Catch {
    Write-Error "Unable to add $((Get-ADUser -Filter {(SID -eq $DefaultAdministratorSID)}).samaccountname) to IgnoredADUsers"
}

#Filter out possible duplicates even though there never shouldn't be any
$IgnoredADUsers = $IgnoredADUsers.ToArray() | Select-Object -Unique

#Find users who haven't logged in in 90 days, we use 104 since it is 90+14. The lastlogontimestamp is a replicated attribute and is 14 days behind at times. This is purely for scale and to avoid latency across a wan
$ADUsers = Get-ADUser -Filter {(Enabled -eq $true)} -Properties lastLogonTimestamp,DisplayName |
    Select-Object DisplayName,samaccountname,@{Name='LastLogonDate';Expression={[datetime]::FromFileTime($PSItem.lastlogontimestamp)}} |
    Sort-Object LastLogonDate |
    Where-Object {($psitem.LastLogonDate -LT (Get-Date).AddDays(-104)) -and ($IgnoredADUsers -notcontains $psitem.samaccountname)}