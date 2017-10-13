function Set-ADUsersProxyAddresses {
    <#
    .SYNOPSIS
    Set AD Proxy Addresses for Users
    
    .DESCRIPTION
    Set AD AD Proxy Addresses and primary mail address for AD users while clearing their existing or keeping the existing
    
    .PARAMETER samaccountname
    User's samaccountname
    
    .PARAMETER PrimarySMTPAddress
    User's primary send and receive SMTP address
    
    .PARAMETER SIPAddress
    User's SIP address, usually the same as their PrimarySMTPAddress
    
    .PARAMETER ProxyAddresses
    User's proxyaddresses
    
    .PARAMETER X500Address
    User's legacy X500 addresse
    
    .PARAMETER KeepExistingProxyAddress
    Switch to keep the users existing proxyaddresses
    
    .EXAMPLE
    Set-ADUsersProxyAddresses -samaccountname wkirkland-test -PrimarySMTPAddress wkirkland-test@email.com -SIPAddress wkirkland-test@email.com -ProxyAddresses 'Hello.World@ministrybrands.com','TheDarkKnight2@ministrybrands.com'` -X500Address 'x500:/o=MEX08/ou=Exchange Administrative Group (FYDIBOHF23SPDLT)/cn=Recipients/cn=6233b4d97389461d9791d7c8b555dfda-wesley.kirkland'
    
    .NOTES
    This is a easy way to one off update users proxy addresses
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,Position=0)] 
        [string]$samaccountname,
        
        [Parameter(Mandatory=$false,Position=1)] 
        [string]$PrimarySMTPAddress = $null,

        [Parameter(Mandatory=$false)] 
        [string]$SIPAddress = $null,

        [Parameter(Mandatory=$false)] 
        [string[]]$ProxyAddresses = $null,

        [Parameter(Mandatory=$false)] 
        [string]$X500Address = $null,

        [Parameter(Mandatory=$false)]
        [switch]$KeepExistingProxyAddress
    )

    Begin {
        Write-Verbose 'Finding a DC to commit changes to'

        $DC = Get-ADDomainController -Discover | Select-Object -ExpandProperty HostName

        if (!(Test-Connection -Count 1 -ComputerName $DC)) {
            Write-Error -Message "Unable to communicate to $DC, exiting now"
            exit
        }
    }

    Process {
        if (!($KeepExistingProxyAddress)) {
            Write-Verbose "We will clear all the proxy addresses for $samaccountname"
            Set-ADUser -Identity $samaccountname -Clear proxyAddresses -Server $DC
        }
        
        #Make a blank object to store the new Addresses/Proxy Addresses to
        $AddressesObject = New-Object -TypeName psobject

        Write-Verbose "Were going to modify the Proxy Addresses for $samaccountname"
        if ($PrimarySMTPAddress) {
            Write-Verbose 'Found a Primary SMTP Address'
            $AddressesObject | Add-Member -MemberType NoteProperty -Name 'mail' -Value "SMTP:$($PrimarySMTPAddress)"
        }

        if ($SIPAddress) {
            Write-Verbose 'Found a SIP Address'
            $AddressesObject | Add-Member -MemberType NoteProperty -Name 'SIP' -Value "SIP:$($SIPAddress)"
        }

        if ($ProxyAddresses) {
            Write-Verbose 'Found Proxy Addresses'
            [System.Collections.ArrayList]$ProxyAddressesTemp = @()
            foreach ($Proxy in $ProxyAddresses) {
                Try {
                    $ProxyAddressesTemp.Add(("smtp:$($Proxy)")) | Out-Null
                }
                Catch {
                    Write-Error 'Failed to add the proxy address to the ArrayList'
                }
            }

            #Add the proxyaddresses to the array
            $AddressesObject | Add-Member -MemberType NoteProperty -Name 'ProxyAddresses' -Value $ProxyAddressesTemp
        }

        if ($X500Address) {
            Write-Verbose 'Found a X500 Address'
            if (($X500Address.Split(':')[0]) -ceq 'x500') {
                $AddressesObject | Add-Member -MemberType NoteProperty -Name 'X500' -Value $X500Address
            } else {
                $AddressesObject | Add-Member -MemberType NoteProperty -Name 'X500' -Value "x500:$($X500Address)"
            }
        }

        if (($AddressesObject | Get-Member -MemberType NoteProperty).Count -gt 0) {
            #Find proxy addresses to populate
            $AttributesForProxyAddresses =  $AddressesObject |
                Get-Member -MemberType NoteProperty |
                Select-Object -ExpandProperty Name

            #Build a arraylist for the proxy addresses
            [System.Collections.ArrayList]$ProxyAddressesArray = @()

            if ($KeepExistingProxyAddress) {
                $ExistingProxyAddresses = Get-ADUser -Identity $samaccountname -Properties ProxyAddresses -Server $DC | Select-Object -ExpandProperty ProxyAddresses

                foreach ($Proxy in $ExistingProxyAddresses) {
                    Try {
                        $ProxyAddressesArray.Add($Proxy) | Out-Null
                    } Catch {
                        Write-Error "Failed to add existing $Proxy to ProxyAddressesArray"
                    }
                }
            }

            foreach ($Attribute in $AttributesForProxyAddresses) {
                $AttributeSplit = $AddressesObject.$Attribute.Split(',')
                
                foreach ($Split in $AttributeSplit) {
                    Try {
                        $ProxyAddressesArray.Add($Split) | Out-Null
                    } Catch {
                        Write-Error "Failed to add $Attribute to ProxyAddressesArray"
                    }
                }
            }

            Write-Verbose 'Removing duplicates from the ProxyAddressesArray'
            #https://community.spiceworks.com/topic/1212728-converting-powershell-object-to-an-array-maybe
            $ProxyAddressesArray = [string[]]($ProxyAddressesArray | Select-Object -Unique)

            Set-ADUser -Identity $samaccountname -Replace (@{ProxyAddresses = $ProxyAddressesArray.ToArray()}) -Server $DC
        

            if ($AddressesObject.mail) {
                Set-ADUser -Identity $samaccountname -EmailAddress $PrimarySMTPAddress -Server $DC
            }
        }
    }

    End {}
}