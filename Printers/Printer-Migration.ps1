<#
.SYNOPSYS
	.
.DESCRIPTION
	Script designed to help automate printer migrations
    Requires Powershell Version 4 on the client side
.EXAMPLE
	Printer-Migration.PS1
.NOTES
	Script to help automate printer migrations, was designed for 2003 x86 to 2008 R2 specifically buts work in other variations.
	Wesley Kirkland 11/29/2014
#>

#Requires –Version 4 

#Output Possible Printer Actions
Write-host "1 = Export Printers"
Write-host "2 = Import Printers"

#Variables
#$tempfolder = $env:TEMP
$tempfolder = "C:\temp"

#Do not edit anything below this line

#Begin Functions
function Get-TempFolder {
    #Function to Verify the temp folder exists for printers, this must be ran as a admin if you use a folder outside of your profile.
    $tempcheck = test-path $tempfolder -ErrorAction SilentlyContinue
    if (!($tempcheck)) {
        New-Item -Path $tempfolder -ItemType dir | Out-Null
    }
}

function show-csvhelp {
    Write-host "Please open the the csv and remove any printers you do not want to import such as PDF and XPS printers."
    Write-Host ""
    Write-host "Open the File in Excel and make a column named IPAddress, this will be the ip addresses listed in the port name most likely."
    Write-host "I suggest using Text-Columns to make this easier just keep a copy of PortName."
    Write-Host ""
    Write-host "Change the Drivers to match the imported drivers"
    Write-host "That is it!"
    Write-Host ""
    Write-host "Rerun the script and chose option 2"
}

function Get-CurrentPrinters {
    #Verify the Temp Folder Exists
    Write-Host '' #For Formatting
    write-host "The Exported file is located in $tempfolder\$printserver-printerexport.csv"
    Get-TempFolder
    #Begin Printer Export
    $printserver = Read-host "What is the current print server?"
    Get-WMIObject -class Win32_Printer -computer $printserver | select Name,DriverName,PortName,ShareName,Comment | Export-CSV -path "$tempfolder\$printserver-printerexport.csv" -NoTypeInformation
    #Show the Help Function, I could have put it here but I figured have the help in a function for a more moduler design
    Show-CSVHelp
}

function New-PrinterPort {
    #From the Interwebs, this creates the printer port for us to use, when we add the printer.
        $server = $args[0] 
        $port = ([WMICLASS]"\\$printserver\ROOT\cimv2:Win32_TCPIPPrinterPort").createInstance()
        $port.Name = $args[1]
        $port.SNMPEnabled = $false
        $port.Protocol = 1 
        $port.HostAddress = $args[2]
        $port.Put() 
    }

function New-FileItemSelection {
#Function to build a menu from the $temp
#From the interwebs
#The output selection from this function is $file
$menu = @{}
$files =  Get-childItem -Path $tempfolder | Where-Object {$_.Name -like "*.csv"}
    for ($i = 0; $i -lt $files.count; $i ++)
    {
        $menu.Add($i,$files[$i])
        Write-Host ($i + 1) $files[$i]
    }
    [int]$ans = Read-Host 'Choose the csv to import'
    write-host "Please select which CSV you would like to import."
    $file = $menu.Item($ans - 1) | select name | Select-Object -First 1
    $file.Name | Select-Object -First 1 | Set-Variable -Name file -scope 1 -ErrorAction SilentlyContinue
}

function New-Printer {
    #Function to Add the Printer to the print server.
    #Also know as Function Do-Stuff
    New-FileItemSelection
    write-host ''
    write-host "This can take up to a minute a printer"
    $printserver = Read-Host "What is the Print Server we are installing on?"
    #We are appending the $tempfolder to $file
    $printers = import-csv $tempfolder\$file

    #Checking if user added the right headers
    if (!($printers.IPAddress -gt '1')) {
            write-host "It Seems like you didn't setup the csv correct, you should really read the directions."
            exit
        }

    foreach ($printer in $printers) {
            New-PrinterPort $printserver $printer.Portname $printer.IPAddress
            Add-Printer -Name $printer.Name -ShareName $printer.ShareName -computername $printserver -drivername $printer.DriverName -PortName $printer.PortName -Comment $printer.Comment -Published:$false -Shared:$True
            Write-Host -ForegroundColor White $printer.Name "has been added to $printserver"  
        }
}

#Printer Selection Input Message 
$printerSelection = Read-Host "Which Printer Action?" 

#Replacing $printeraction with $printerSelection, this allows to expand the script later on if need be.
$printeraction = $printerSelection 
 
if(!($printeraction)) { 
    Throw "You did not select a valid printer option"
    Exit 
} 
 
Switch($printeraction) { 
    1 {Get-CurrentPrinters} 
    2 {New-Printer}
    default { 
    $errorMessage
    Exit 
    } 
} 
# *** End Menu Selection Code Block