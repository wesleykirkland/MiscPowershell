<#
    .SYNOPSIS
    This script is designed to help aid in creating Shares for protected access
    
    .DESCRIPTION
    This script will take the correct input and create a new folder on a share with broken inheritiance to apply specific permissions
    Author: Wesley Kirkland
    
    .PARAMETER Folder_Name
    The Folder name to be created

    .PARAMETER Path
    The root folder path, if a trailing \ is provided it will be trimmed off

    .PARAMETER ADGroupOwner
    Friendly name of who will own the group

    .PARAMETER GroupType
    Specify if the Group will be List,ReadAndExecute, or Modify

    .PARAMETER OU
    Specify a Custom OU to create the group in

    .PARAMETER Members
    List members in an array with a ',' delimiter

    .EXAMPLE
    C:\Scripts> Security_Folder_and_Group_Creation.ps1 -Folder_Name "Test1" -Path "\\server\share\Photos" -AdGroupOwner "Wesley Kirkland" -GroupType Modify

    This is the most basic form of the script to create a framework in the default Corp Groups OU

    .EXAMPLE
    C:\Scripts> Security_Folder_and_Group_Creation.ps1 -Folder_Name "Test1" -Path "\\server\share\Photos" -AdGroupOwner "Wesley Kirkland" -GroupType Modify -OU "OU=MORs,OU=Groups,OU=Corp,DC=DOMAIN,DC=COM"

    This is the most basic form of the script to create a framework in a custom OU

    .EXAMPLE
    C:\Scripts> Security_Folder_and_Group_Creation.ps1 -Folder_Name "Test1" -Path "\\server\share\Photos" -AdGroupOwner "Wesley Kirkland" -GroupType Modify -OU "OU=MORs,OU=Groups,OU=Corp,DC=DOMAIN,DC=COM" -Members samaccountname1,samaccountname2

    Best way to run the script to avoid extra work, a OU is being specified as well as members to be added to the group. To add members a comma must be used

    .EXAMPLE
    C:\Scripts> Security_Folder_and_Group_Creation.ps1 -Folder_Name "Test1" -Path "\\server\share\Photos" -AdGroupOwner "Wesley Kirkland" -GroupType Modify -Members samaccountname1,samaccountname2

    Same as above except the default OU will be used
#>

#Requires
#Requires -Modules NTFSSecurity
#Requires -PSSnapin Quest.ActiveRoles.ADManagement
#Requires -Modules ActiveDirectory
#Requires -Version 4

[CmdletBinding()]
  param (
    [Parameter(Mandatory=$true)]
    [string]$Folder_Name,
    [Parameter(Mandatory=$true)]
    [string]$Path,
    [Parameter(Mandatory=$true)]
    [string]$ADGroupOwner,
    [Parameter(Mandatory=$true)]
    [ValidateSet("Modify","List","ReadAndExecute")]
    [String]$GroupType,
    [Parameter(Mandatory=$false)]
    [string]$OU = "OU=Groups,OU=Corp,DC=INSERTDOMAIN,DC=INSERTTLD",
    [Parameter(Mandatory=$false)]
    [array]$Members
    )


#Requires
#Requires -Modules NTFSSecurity
#Requires -PSSnapin Quest.ActiveRoles.ADManagement
#Requires -Modules ActiveDirectory

#Global Variables
$DNS = $env:USERDNSDOMAIN
$Domain = $DNS.split(".")[0]
$TLD = $DNS.split(".")[1]
#$OU = "OU=Groups,OU=Corp,DC=$Domain,DC=$TLD" #Custom OU if you want it
$DC = Get-ADDomain | Select-Object -ExpandProperty PDCEmulator #I like to hit the PDC Emulator so AD updates quicker for the primary site aka the Datacenter

#See if whe are in a child domain other the OU Remangler will fail
if (($DNS.Split('.') | measure).Count -gt 2) {
    Write-Warning "I think your in a child domain, I can't run like this. If you still want to use me please redo some code to account for the extra DC in the string and take this segment out"
    Start-Sleep -Seconds 5
    exit
}

#Remangle the OU becuase of a powershell limitation where a CMDLet binding has to be first
$OU = $OU.Replace("INSERTDOMAIN",$Domain).Replace("INSERTTLD",$TLD)

#Add Snapins for Quest, we are requiring them above
Get-PSSnapin -Registered | Add-PSSnapin

#Test-Connection to the PDC
if (!(Test-Connection -ComputerName $DC -Count 2)) {
    Write-Warning "Can not connect to $DC!, I will now exit"
    Start-Sleep -Seconds 5
    exit
}

#################################################################################################################################################################################################################################
#Code Starts Below, Do not modify
#################################################################################################################################################################################################################################
#Build Variables for the script to run
$FolderPath = ($Path + "\" + $Folder_Name).TrimEnd("\")
$GroupName = ($FolderPath + "-$GroupType").Substring(2).Replace("\","-").ToUpper()

#Check if the Group Name will be over 64 characters if so fail out
If ($GroupName.Length -gt 64) {
    Write-Warning "The group name will be over 64 characters, I will now exit"
    exit
}

#Create Folder
New-Item -Path $FolderPath -ItemType Dir

#Disable Inheritiance on the folder
Disable-NTFSAccessInheritance -Path $FolderPath

#Create AD Group
New-ADGroup -Name $GroupName -SamAccountName $GroupName -GroupScope Global -Description $FolderPath -GroupCategory Security -Path $OU -Server $DC

#Set Group Notes because the AD cmdlet pretty much suck!
Set-ADGroup -Identity $GroupName -Replace @{info=$ADGroupOwner} -Server $DC

#Switch statement to figure out what kind of group of access to apply to the group
switch ($GroupType) {
    "ReadAndExecute" {$AccessType = "ReadAndExecute"}
    "Modify" {$AccessType = "Modify"}
    "List" {$AccessType = "ListDirectory"}
}

#Add group to Modify on the folder, The Get-ADGroup is nested since Add-NTFSAccess does not support a direct -Server command and replication is not fast enough even in InterSite
Add-NTFSAccess -Path $FolderPath -Account (Get-ADGroup -Identity $GroupName -Server $DC).SID -AccessRights $AccessType 

#Add Members if any where specified
if ($Members -notlike $null){
    Add-ADGroupMember -Identity $GroupName -Members $Members
}