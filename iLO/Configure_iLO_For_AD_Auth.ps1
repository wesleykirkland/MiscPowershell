#Requires -Modules HPiLOCmdlets
#Requires -Version 4
<#
    .SYNOPSIS
    This script will preconfigure HP iLOs to our Standards
    
    .DESCRIPTION
    This script will take the input of a DNS name or IP address and configure the iLO, it will first check if the iLO is version 3 and above and if it can authenicate to it. It will configure the iLO for AD Authenication and then reset the iLO password, you will need to add it to cyberark afterwards
    Author: Wesley Kirkland
    Last Updated: 06-01-2016
    
    .PARAMETER servers
    Specify an array of DNS Names, or IP Addresses

    .PARAMETER password
    Specifiy a password other then Password

    .PARAMETER UseExistingiLOKey
    If this switch is specified the script will use the existing iLO license

    .PARAMETER iLOLicense
    This has a default value, type in a new license if you wish to use a different key

    .EXAMPLE
    Configure_iLO_For_AD_Auth.ps1 -servers loc-servername-ilo
    This is the most basic example

    .EXAMPLE
    Configure_iLO_For_AD_Auth.ps1 -servers iLOIPAddress
    This is the most basic example but with an IP Address, lots of warnings will come back if you use this methods

    .EXAMPLE
    Configure_iLO_For_AD_Auth.ps1 -servers loc-servername-ilo -password 'RandomPasswordOfTheDay'
    Configure the iLO with a different local admin password

    .EXAMPLE
    Configure_iLO_For_AD_Auth.ps1 -servers loc-servername-ilo -password 'RandomPasswordOfTheDay' -UseExistingiLOLicense
    This will use the existing iLO license

    .EXAMPLE
    Configure_iLO_For_AD_Auth.ps1 -servers loc-servername-ilo -password 'RandomPasswordOfTheDay' -iLOLicense xxxx-xxxxx-xxxxx-xxxxx-xxxxx
    This will specify a custom iLO Key
#>

#CMDLet Binding
[CmdletBinding()]
  param (
    [Parameter(Mandatory=$true,Position=0,HelpMessage='This can be a single value or an array')]
    [array]$servers,

    [Parameter(Mandatory=$false,Position=1,HelpMessage='This is the password to login to iLO with')]
    [string]$password = 'Password',
    
    [Parameter(Mandatory=$false,HelpMessage='iLO License to install to the system')]
    [string]$iLOLicense = 'XXXXX-XXXXX-XXXXX-XXXXX-XXXXX',

    [Parameter(Mandatory=$false,HelpMessage='Choose wether or not to replace the iLO key or use the existing one')]
    [switch]$UseExistingiLOKey = $false
)

#Variables
[string]$username = 'Administrator'
#Hashed string of password to set the iLO to
$cred = Get-Credential #Feel free to store it if you would like
[string]$ldap = 'ldap.domain.com'
[string]$ServerPort = '636' #Do not set as a int, this needs to stay as a string
[int]$MiniLOVersion = '3'

#C Sharp code to ignore SSL errors
Add-Type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

foreach ($server in $servers) {
    Write-Output "Parsing $server"
    Write-Verbose "Test for iLo version as it needs to be higher than $MiniLOVersion"

    #Resolve DNS to an IP using .Net
    if ($server -match '[a-z]') {$iLOIPAddress = [System.Net.Dns]::GetHostAddresses($server).IPAddressToString} else {$iLOIPAddress = $server}

    #Find the HP iLO version using some string hacking
    $iLoVersion = Find-HPiLO -Range $iLOIPAddress -WarningAction SilentlyContinue | Select-Object -ExpandProperty PN
    $pos = $iLoVersion.IndexOf('(') #Find the character position of the '('
    $rightpart = $iLoVersion.Substring($pos+1) #To the right of the position index
    $iLoVersion = (($rightpart) -replace '\D+(\d+)','$1').Replace(')','') #Get the final iLO version :)
    Write-Verbose "The iLO version of $server is $iLoVersion"
    
    #Test authenication to the iLO
    if ((Get-HPiLODefaultLanguage -Server $server -Username $username -Password $password).STATUS_MESSAGE -like "OK") {$AuthToiLO = $true} else {$AuthToiLO = $false}


    #Verify iLO License is high enough for the script to run and verify we can communicate with the iLO as well
    if (($iLoVersion -ge $MiniLOVersion) -and (Test-Connection -ComputerName $server -Count 1) -and $AuthToiLO) {
        #Check if we are replacing the iLO Key or not
        if (!($UseExistingiLOKey)) {
            Write-Verbose "Configure HP iLO License Key"
            Set-HPiLOLicenseKey -Server $Server -Username $username -Password $password -Key $iLOLicense
        }

        Write-Verbose "Configuring iLO on $server"
        Write-Verbose "Configure the iLO Administration> Security> Directory settings"
        Set-HPiLODirectory -Server $server -Username $username -Password $password -ServerAddress $ldap -ServerPort 636 -UserContext1 'OU=Restricted,OU=Groups,OU=IT,DC=DOMAIN,DC=COM'-ObjectDN $null -LDAPDirectoryAuthentication Use_Directory_Default_Schema

        Write-Verbose "Flip the Kerberos Authenication Radio Button to enabled on the previous step"
        Set-HPiLOKerberosConfig -Server $server -Username $username -Password $password -KerberosAuthentication Yes

        Write-Verbose "Rename Group 1 so it doesn't use Administrators but our retricted group, also the GroupXPrivs is broken when you try to set them from Powershell"
        Set-HPiLOSchemalessDirectory -Server $server -Username $username -Password $password -Group1Name 'CN=iLO-Administrators,OU=Restricted,OU=Groups,OU=IT,DC=DOMAIN,DC=COM'

        Write-Verbose "Set the iLO Password correctly"
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($cred.Password); $PasswordToSetToiLO = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR) #Password magic to get the password back
        Set-HPiLOPassword -Server $server -Username $username -Password $password -UserLoginToEdit Administrator -NewPassword $PasswordToSetToiLO

        Write-Verbose "Configure DNS settings for iLO, this will also reboot the ilo"
       
        #Check to make sure they ara alphanumberic characters and not a IP address. Can't put in the cmdlet since it won't parse properly
        if ($server -match '[a-z]') {
            Write-Verbose 'The $server variable appeared to have alphanumeric characters so I entered the default statement'
            Write-Verbose 'Configure IPV4'
            Set-HPiLONetworkSetting -Server $server -Username $username -Password $PasswordToSetToiLO -DNSName ($server) -Domain "domain.com" -PrimDNSServer "192.168.1.1" -SecDNSServer "192.168.1.1" -DHCPSNTP No -SNTPServer1 '192.168.1.1' -SNTPServer2 '192.168.1.1' -Timezone 'Etc/GMT+4' -ErrorAction SilentlyContinue | Out-Null
            
            Write-Verbose 'Disable IPV6'
            Set-HPiLOIPv6NetworkSetting -Server $server -Username $username -Password $PasswordToSetToiLO -DHCPv6SNTPSetting Disable
            
            Write-Verbose 'Default sleep to allow the iLO to turn off, then ping it until it comes back on'
            Start-Sleep -Seconds 5
            do {Start-Sleep -Seconds 1} until (Test-Connection -ComputerName $server -Count 1 -ErrorAction SilentlyContinue)
        } else {
            Write-Verbose 'The $server variable appeared to be an IP address, I will not set the'
            Write-Verbose 'Configure IPV4'
            Set-HPiLONetworkSetting -Server $server -Username $username -Password $PasswordToSetToiLO -Domain "domain.com" -PrimDNSServer "192.168.1.1" -SecDNSServer "192.168.1.1" -DHCPSNTP No -SNTPServer1 '192.168.1.1' -SNTPServer2 '192.168.1.1' -Timezone 'Etc/GMT+4' -ErrorAction SilentlyContinue | Out-Null

            Write-Verbose 'Default sleep to allow the iLO to turn off, the ping it until it comes back on'
            Start-Sleep -Seconds 5
            do {Start-Sleep -Seconds 1} until (Test-Connection -ComputerName $server -Count 1 -ErrorAction SilentlyContinue)

            Write-Verbose 'Disable IPV6'
            Set-HPiLOIPv6NetworkSetting -Server $server -Username $username -Password $PasswordToSetToiLO -DHCPv6SNTPSetting Disable
        }
    Write-Output "Please attempt to login via AD on the new iLO, thanks. If it does not work check the DNS settings as sometime they will fail to set"
    } else {Write-Warning "$server does not have iLO $MiniLOVersion or higher, or authenication failed."}
}