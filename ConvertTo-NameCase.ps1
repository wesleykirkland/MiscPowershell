function ConvertTo-NameCase ([string[]]$Names) {
    <#
    .SYNOPSIS
    ConvertTo-NameCase takes any english name variation and converts it to the correct case format

    .DESCRIPTION
    ConvertTo-NameCase takes any english name variation and converts it to the correct case, it will handle upper, lower, hyphens, and apostrophe 

    .PARAMETER Name
    Name The name you wish to correct in the form of a string

    .EXAMPLE
    ConvertTo-NameCase -Names "kevin"
    #Output = Kevin
    ConvertTo-NameCase -Names "kevin" "o'leary"
    #Output = Kevin
    #O'Leary

    .NOTES
    General notes
    #>
    foreach ($Name in $Names) {
        $NameArray = $Name.ToCharArray() #Get a Character array, basically a split
        #Loop through the array and do the correct case
        for ($i = 0; $i -lt $Name.Length; $i++) {
            $NameArray[0] = ([string]$Name[0]).ToUpper()
            if ($NameArray[$i] -eq '-' -or $NameArray[$i] -eq "'") {
                $NameArray[$i + 1] = ([string]$NameArray[$i + 1]).ToUpper() 
                $i++ #Tell the loop to skip the next itteration
            } else {
                $NameArray[$i] = ([string]$Name[$i]).ToLower()
            }
        }
        $NameArray -join '' #Join the Character Array back into a string
    }
}