function Check-Creds {
    [CmdletBinding()]
        Param(
        [Parameter(Mandatory=$true,Position=1)]
        $CheckCred = $cred
    )

    $username = $CheckCred.username
    $password = $CheckCred.GetNetworkCredential().password

    # Get current domain using logged-on user's credentials
    $CurrentDomain = "LDAP://" + ([ADSI]"").distinguishedName
    $checkdomain = New-Object System.DirectoryServices.DirectoryEntry($CurrentDomain,$UserName,$Password)

    if ($checkdomain.name -eq $null) {
        Write-Host "Authentication failed - please verify your username and password."
        #exit #terminate the script.
        } else {
        Write-Host "Successfully authenticated with domain" $checkdomain.name
    }
}
