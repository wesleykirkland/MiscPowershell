<<<<<<< HEAD
﻿<#
.SYNOPSIS
	Get errors in a select event log
.DESCRIPTION
	Checks to see if the computer is online then gets the requested event logs
.PARAMETER ComputerName
	Name of the Server to query
.PARAMETER Log
	Name of the Log to query, default is All
.EXAMPLE
	Event-Log-QA.PS1 <server>
.NOTES
	Script to create local admins group for server builds and / or add accounts to the group
	Initial Wesley Kirkland 12/05/2014
    Update C. David Littlejohn 04/14/2017
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0, ValueFromPipeline = $true)]
    $ComputerName = '.',

    [Parameter(Position = 1)]
    [String]$log = 'All'
)

$temp = "C:\temp\qa"
$ComputerName | Set-Variable computername -Scope Script

if ($ComputerName -eq '.') {$ComputerName = Read-Host "What is the Server you want to check?"}
else {}

#Check if the computer is online
if (!(Test-Connection $ComputerName -Count 1 -Quiet)) {
    Write-Warning "Computer is not online, exiting application"
    exit
}

function get-eventlogerrors {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromPipeline = $true)]
        $ComputerName = '.',

        [Parameter(Position = 1)]
        [String]$logName = '.'
    )

    #Get-EventLog Seems to be Faster, just uncomment one and comment the other if need be
    #Get-WinEvent -LogName $logName -ComputerName $ComputerName | where {($_.LevelDisplayName -eq "Error") -or ($_.LevelDisplayName -eq "Critical")} | select TimeCreated,Id,ProviderName,LevelDisplayName,Message | sort TimeCreated -Descending | export-csv $temp\$ComputerName-$logname.csv -NoTypeInformation
    Get-EventLog -LogName $logName -ComputerName $ComputerName | Where-Object {($_.EntryType -eq "Error") -or ($_.EntryType -eq "Critical")} | Select-Object TimeGenerated, InstanceID, Source, EntryType, Message | Sort-Object TimeGenerated -Descending | export-csv $temp\$ComputerName-$logname.csv -NoTypeInformation -Force
}

function get-eventlogsize {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromPipeline = $true)]
        $ComputerName = '.',

        [Parameter(Position = 1)]
        [String]$logName = '.'
    )
    $eventlogsize = Get-WmiObject -ComputerName $ComputerName -Class Win32_NTEventLogFile -filter "LogFileName = '$logName'"
    $eventlogsize.MaxFileSize | Set-Variable s5ize -Scope Script

    #Event Sizes to match log sizes
    $masterlogsize = '65536000'

    #If statement to verify log size
    if ($masterlogsize -eq $size) {write-host "$logName Size is 64 Megs, you are good to go" | Set-Variable sizeconfirmed -Scope Script}
    else {
        Write-Warning "Size is Not Right Please Check" | Set-Variable sizeconfirmed -Scope Script
        $currentsize = $eventlogsize.MaxFileSize
        Write-Warning "This current size is $currentsize"
    }
}

if ($log -eq 'All') {
    #Run Functions Against Event Logs we check
    #Application
    get-eventlogerrors $ComputerName Application
    get-eventlogsize $ComputerName Application
    #System
    get-eventlogerrors $ComputerName System
    get-eventlogsize $ComputerName System
    #Security
    get-eventlogerrors $ComputerName Security
    get-eventlogsize $ComputerName Security
    
    #User Message
    write-host "Event Log Output is stored in $temp\$ComputerName-*.csv"
    invoke-item $temp -ErrorAction SilentlyContinue
}
else {
    #Run Functions Against the log that was specified.
    get-eventlogerrors $ComputerName $log
    get-eventlogsize $ComputerName $log
    #User Message
    write-host "Event Log Output is stored in $temp\$ComputerName-$log.csv"
    invoke-item $temp -ErrorAction SilentlyContinue
}
=======
﻿<#
.SYNOPSIS
	Get errors in a select event log
.DESCRIPTION
	Checks to see if the computer is online then gets the requested event logs
.PARAMETER ComputerName
	Name of the Server to query
.PARAMETER Log
	Name of the Log to query, default is All
.EXAMPLE
	Event-Log-QA.PS1 <server>
.NOTES
	Script to create local admins group for server builds and / or add accounts to the group
	Initial Wesley Kirkland 12/05/2014
    Update C. David Littlejohn 04/14/2017
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0, ValueFromPipeline = $true)]
    $ComputerName = '.',

    [Parameter(Position = 1)]
    [String]$log = 'All'
)

$temp = "C:\temp\qa"
$ComputerName | Set-Variable computername -Scope Script

if ($ComputerName -eq '.') {$ComputerName = Read-Host "What is the Server you want to check?"}
else {}

#Check if the computer is online
if (!(Test-Connection $ComputerName -Count 1 -Quiet)) {
    Write-Warning "Computer is not online, exiting application"
    exit
}

function get-eventlogerrors {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromPipeline = $true)]
        $ComputerName = '.',

        [Parameter(Position = 1)]
        [String]$logName = '.'
    )

    #Get-EventLog Seems to be Faster, just uncomment one and comment the other if need be
    #Get-WinEvent -LogName $logName -ComputerName $ComputerName | where {($_.LevelDisplayName -eq "Error") -or ($_.LevelDisplayName -eq "Critical")} | select TimeCreated,Id,ProviderName,LevelDisplayName,Message | sort TimeCreated -Descending | export-csv $temp\$ComputerName-$logname.csv -NoTypeInformation
    Get-EventLog -LogName $logName -ComputerName $ComputerName | Where-Object {($_.EntryType -eq "Error") -or ($_.EntryType -eq "Critical")} | Select-Object TimeGenerated, InstanceID, Source, EntryType, Message | Sort-Object TimeGenerated -Descending | export-csv $temp\$ComputerName-$logname.csv -NoTypeInformation -Force
}

function get-eventlogsize {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromPipeline = $true)]
        $ComputerName = '.',

        [Parameter(Position = 1)]
        [String]$logName = '.'
    )
    $eventlogsize = Get-WmiObject -ComputerName $ComputerName -Class Win32_NTEventLogFile -filter "LogFileName = '$logName'"
    $eventlogsize.MaxFileSize | Set-Variable s5ize -Scope Script

    #Event Sizes to match log sizes
    $masterlogsize = '65536000'

    #If statement to verify log size
    if ($masterlogsize -eq $size) {write-host "$logName Size is 64 Megs, you are good to go" | Set-Variable sizeconfirmed -Scope Script}
    else {
        Write-Warning "Size is Not Right Please Check" | Set-Variable sizeconfirmed -Scope Script
        $currentsize = $eventlogsize.MaxFileSize
        Write-Warning "This current size is $currentsize"
    }
}

if ($log -eq 'All') {
    #Run Functions Against Event Logs we check
    #Application
    get-eventlogerrors $ComputerName Application
    get-eventlogsize $ComputerName Application
    #System
    get-eventlogerrors $ComputerName System
    get-eventlogsize $ComputerName System
    #Security
    get-eventlogerrors $ComputerName Security
    get-eventlogsize $ComputerName Security
    
    #User Message
    write-host "Event Log Output is stored in $temp\$ComputerName-*.csv"
    invoke-item $temp -ErrorAction SilentlyContinue
}
else {
    #Run Functions Against the log that was specified.
    get-eventlogerrors $ComputerName $log
    get-eventlogsize $ComputerName $log
    #User Message
    write-host "Event Log Output is stored in $temp\$ComputerName-$log.csv"
    invoke-item $temp -ErrorAction SilentlyContinue
}
>>>>>>> origin/master
