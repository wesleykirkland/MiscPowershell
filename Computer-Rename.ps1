<#
.SYNOPSYS
        When you run the script it will check if you have ran the script all the way previously based upon the site prefix. If you have not it will help you build a computer name. Once the computer name is built it will check if it exists inside of AD and if it does not it will rename the computer to the new name.
    When you run the script after the first time time it runs a quick check to see if the prefix is the same of what you selected before. If it is the script checks if the computer is joined to a domain, if so it exits. If not it will jooin it to the domain and reboot.
.DESCRIPTION
        Script designed to rename computers against a defined list of site names
.EXAMPLE
        Computer-Rename.PS1
.NOTES
        http://reddit.com/u/creamersrealm 12/03/2014
#>
 
##########################################################################################################################################################
#This goes against best practice but it has to go here for the creds to not make the script fail.
Function Test-Administrator {
    #Function to check if we are running as admin  
    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator) | Set-Variable isadmin -Scope Script
}
 
#Test if we are running as Administrator
Test-Administrator
if ($isadmin -eq $false) {
    Write-Host "You are not running as Administrator, please relaunch and run as Administrator."
    exit
} else {}
 
#Check for Powershell Version 4.0 and .Net 4.X, if 4.0 or above is installed then the script will continue
#For Powershell Updater
$DotNetUrl = "http://server.domain.com/scripts/dotNET"
$WMFUrl = "http://server.domain.com/scripts/WMF"
 
Function get-FileFromUri {
# This function downloads a file in PowerShell 2.0.
# Example: get-FileFromUri http://example.com/url/of/example/file C:\example-folder
param(
[parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
[string]
[Alias('Uri')]
$Url,
[parameter(Mandatory=$false, Position=1)]
[string]
[Alias('Folder')]
$FolderPath
)
process {
try {
# resolve short URLs
$req = [System.Net.HttpWebRequest]::Create($Url)
$req.Method = "HEAD"
$response = $req.GetResponse()
$fUri = $response.ResponseUri
$filename = [System.IO.Path]::GetFileName($fUri.LocalPath);
$response.Close()
# download file
$destination = (Get-Item -Path ".\" -Verbose).FullName
if($FolderPath) { $destination = $FolderPath }
if ($destination.EndsWith('\')) {
$destination += $filename
} else {
$destination += '\' + $filename
}
$webclient = New-Object System.Net.webclient
$webclient.downloadfile($fUri.AbsoluteUri, $destination)
write-host -ForegroundColor DarkGreen "downloaded '$($fUri.AbsoluteUri)' to '$($destination)'"
} catch {
write-host -ForegroundColor DarkRed $_.Exception.Message
}
}
}
 
function Update-Powershell {
#Update Powershell Function
#Determines Powershell version. Exits the script if it's 4.0
if ($PSVersionTable.PSVersion.Major -ge 4) {
$Date = Get-Date
Write-Host "$Date - Powershell upgrade not needed, you shouldn't see this message if you do please contact Wesley Kirkland in Systems"
}
 
#Determines if DotNet 4.5 is installed, downloads and installs if it is not.
$DotNetVer = (Get-ItemProperty -Path  "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Client").Version
If ($DotNetVer -lt 4.5){
    $FileUrl = "$DotNetUrl/NDP451-KB2858728-x86-x64-AllOS-ENU.exe"
    $FileDest = "$env:Temp"
    $Date = Get-Date
    Write-Host "$Date - Downloading the .Net Framework 4.5 installer"
    Get-FileFromUri $FileUrl $FileDest
    Set-Location "$env:Temp"
    $Date = Get-Date
    Write-Host "$Date - Installing .Net Framework 4.5. This can take some time. The script will continue when it's finished."
    .\NDP451-KB2858728-x86-x64-AllOS-ENU.exe /q /norestart | Out-Null
    #Checks to make sure it installed, exits with an error if not
    $DotNetVer = (Get-ItemProperty -Path  "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Client").Version
    If ($DotNetVer -lt 4.5){
        $Date = Get-Date
        Write-Host "$Date - Install of Dotnet Framework 4.5 failed with error code: $LastExitCode - Exiting the script."
        Exit 1000
        }
    Else {
    $Date = Get-Date
    Write-Host "$Date - Install of Dotnet Framework 4.5 succeeded"
    }
}
 
#Determines the architecture of the machine
$Arch = (Get-WmiObject Win32_OperatingSystem).OSArchitecture
#Sets the name of the Windows Management Framework installed based on architecture
If($Arch -eq "64-Bit") {$WMF = "Windows6.1-KB2819745-x64-MultiPkg.msu"}
    Else {$WMF = "Windows6.1-KB2819745-x86-MultiPkg.msu"}
 
#Downloads and silently installs Windows Management Package
$FileUrl = "$WMFUrl/$WMF"
$FileDest = "$env:Temp"
$Date = Get-Date
Write-Host "$Date - Downloading the Windows Management Package installer."
Get-FileFromUri $FileUrl $FileDest
Set-Location "$env:Temp"
$Date = Get-Date
Write-Host "$Date - Installing the Windows Management Package."
wusa.exe "$WMF" /quiet /norestart | Out-Null
 
#Checks to see if the installed succeeded. When it succeeds, it returns error 3010, which means the computer needs to be rebooted.
If($LastExitCode -eq 3010) {
$Date = Get-Date
Write-Host "$Date - The install of Powershell 4.0 finished. Rebooting in 10 Seconds"
start-sleep -Seconds 10
Restart-Computer
}
    Else {
    $Date = Get-Date
    Write-Host "$Date - The install of Powershell 4.0 failed with error code: $LastExitCode - You may need to manually install."
    Exit 1000
    }
}
 
 
if ($PSVersionTable.PSVersion.Major -lt 4) {Update-Powershell} else {}
#End bad practices
##########################################################################################################################################################
#Variables, this can be changed but I would advise against it
$i = #The string from the cred generator goes here
#Create Drive for Variables
New-PSDrive -Name Y -PSProvider FileSystem -Credential $cred -Root \\sccmservername\sources$
 
#Variables that can be edited
$Submenu = GCI -Path Y:\Sites | where {$_.Attributes -like "Directory"}
#$ErrorActionPreference = 'silentlycontinue'
#$WarningPreference = 'silentlycontinue'
$OU = "OU=GENERATEDCOMPUTERS, DC=DOMAIN, DC=COM"
$LDAPString = "LDAP://ldap.domain.com:389/dc=domain,dc=com"
$domain = "domain.com"
#Variables for Number Incrementing System
$increment = 1n #Leave this as 1
 
#Clear the Screen from Junk
clear
 
##########################################################################################################################################################
#Function Section 2
Function Select-Site {
#Function to select a site, compiled from a UNC path
Begin {
}
 
Process {
write-host "Please Type a site name as it appears"
$submenu | %{$_.name}
Read-Host “You may Select Something from the Submenu” | Set-Variable Selected_Item -Scope Script
if ($Submenu.Name -contains $Selected_Item){} #Continue is it matchs
else {
clear
Write-warning "Not a Valid site, please try again"
start-sleep 0.1
Select-Site}
$Selected_Item | out-file $env:TEMP\sitename.txt
$Selected_Item = $Submenu | ? {$_.name -like “$($Selected_Item)”}
}
}
 
function Search-ADComputer($ComputerName) {  
    $rootEntry = New-Object -TypeName System.DirectoryServices.DirectoryEntry -ArgumentList $LDAPString ,$($Cred.UserName),$($Cred.GetNetworkCredential().password)
    $finder = New-Object System.DirectoryServices.DirectorySearcher($rootEntry)
    $finder.Filter="(&(objectCategory=computer)(cn=" + $ComputerName + "))"
    $finder.SearchScope="subtree"
    $collFinder = $finder.FindAll()
    if ($collFinder.Count) {
        ForEach ($Entry In $collFinder) {
         #Write-Host $ComputerName "already exists" `r`n
        }
        $finder.Dispose()
        $collFinder.Dispose()
        $true | Set-Variable doescomputerexist -Scope Script -ErrorAction SilentlyContinue
    }
    else {  
         #Write-Host $ComputerName "ComputerName does not exist" `r`n
         $finder.Dispose()
         $collFinder.Dispose()
         $false | Set-Variable doescomputerexist -Scope Script -ErrorAction SilentlyContinue
    }
}
 
function Check-AdComputer {
#Function to see if the AD Computer Exists
[CmdletBinding()]
param(
        [Parameter(Position=0)]
        [String]$computer = ""
)
 
#Search AD, Uses above Function to search if the computer name exists. We can not use get-adcomputer since the machine is not domain joined and RSAT is not installed.
Search-ADComputer $computer
 
 
 
if ($doescomputerexist -eq $true)
{
    #If then statement for the Do Until loop that will increment the users computer
    if ($didweincrement -eq $true)
    { #Bracket for Section 1 if Did We Increment is $TRUE
        #This Section of Code Will Take LOC-(LAP)Username01 and convert it to LOC-(LAP)Username02
        #Number Incrementing System
        $increment = $increment + 1
        $newcomputername = $generatedname + $increment
        #We have to store out current increment value increment
        $increment | Set-Variable increment -Scope Script
        $newcomputername  | Set-Variable newcomputername -Scope Script
        write-host "$computer already exists, I incremented the computer name for you."
        Write-Host "The New Name is $newcomputername"
    } #End Section 1
    else
    { #Bracket for Section 2 if Did We Increment is other than $TRUE, else statement
        #This Section of Code Will Take LOC-(LAP)Username and convert it to LOC-(LAP)Username01
        #Number Incrementing System
        $computer + "0" | Set-Variable generatedname -Scope Script
        $newcomputername = $generatedname + $increment
        $newcomputername  | Set-Variable newcomputername -Scope Script
        write-host "$computer already exists, I incremented the computer name for you."
        Write-Host "The New Name is $newcomputername"
    } #End Section 2
} #End If $doescomputerexist -eq $TRUE if else statement, True Section Only. The True section contained Section 1 and 2.
else #If $doescomputerexists -eq $FALSE
    {
        #Set $doescomputerexist to $FALSE
        $false | Set-Variable doescomputerexist -Scope Script
    } #End of the If Else Statement to see if the Computer Name Exists
$true | Set-Variable didweincrement -Scope Script #Set $didweincrement so the script know where it is if it has to increment again
}
 
function New-ComputerName {
#Select which site the machine will belong to
Select-Site
 
#Start Asking Questions
clear
 
$username = read-host "What is the users username?"
$islaptop = read-host "Is this a laptop? Please use Yes or No"
 
#Build the Computername based upon the site, username, islaptop
if ($islaptop -like "YES" -or $islaptop -like "1" -or $islaptop -like "SURE" -or $islaptop -like "Y")
{
    $newcomputername = $Selected_Item + "-" + "LAP" + $username
    $newcomputername = $newcomputername.ToUpper()
    $newcomputername | Set-Variable newcomputername -Scope Script
}
else
{
    $newcomputername = $Selected_Item + "-" + $username
    $newcomputername = $newcomputername.ToUpper()
    $newcomputername | Set-Variable newcomputername -Scope Script
}
}
#End Function Section 2
##########################################################################################################################################################
 
##########################################################################################################################################################
#Actual Script starts here
#Verify Computername to determine where we need to start
$computernamecheck = $env:COMPUTERNAME
$computernamecheck = $computernamecheck.split("-")
$computernamecheck = $computernamecheck.GetValue(0)
$prefix = gc $env:TEMP\sitename.txt
$isdomainjoined = gwmi win32_computersystem
 
if ($computernamecheck -eq $prefix)
{
    #Checking if the Computer is already on a domain
    if ($isdomainjoined.PartOfDomain -eq $true)
    {
        Write-Host "Silly You, TRIX are for Kids!"
    }
    else {
        #Join to the Domain
        Write-Host "Joining to the Domain, rebooting"
        Add-Computer -DomainName $domain -Credential $cred -Restart -OUPath $OU
    }
}
else
{
    #Generate New Computer Name, Based on what the user entered the computer name is stored to $newcomputername
    New-ComputerName
 
    #Do loop to increment until a computername is not found
    Do
    {
        Check-AdComputer $newcomputername
    } Until ($doescomputerexist -eq $false)
 
  #Tell User what the computername will be and that we are restarting in 10 Seconds.
  Write-host "Renaming to $newcomputername, restarting in 10 seconds"
  Start-Sleep -Seconds 10
   
  #Rename Computer
  Rename-Computer -NewName $newcomputername -Restart
 
}
