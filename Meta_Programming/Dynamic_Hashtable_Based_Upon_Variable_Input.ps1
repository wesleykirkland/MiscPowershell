#Setup some sample variables
$varname1 = 1
$varname2 = 2
$varname3 = 3

function MetaDemo1 ([string[]]$Varinput) {
    #Find all variables
    Write-Output "We have the following variables to test: $Varinput"
    
    #Build our Object
    $Object = New-Object -TypeName psobject
    foreach ($Var in $Varinput) {
        $Object | Add-Member -MemberType NoteProperty -Name $Var -Value (Get-Variable -Name $Var).Value
    }

    #Output the Object
    $Object
}

#Specify what the variables names are in a string without the $ variable indicator
MetaDemo1 -Varinput 'varname1','varname2','varname3'

#Sample Output
<#
varname1 : 1
varname2 : 2
varname3 : 3
#>