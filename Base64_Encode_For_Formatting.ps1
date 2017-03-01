Write-Output 'This script will read files as bytes/hex and keep all the random encoding and stuff'
$SourceFile = Read-Host 'What is the file that you would like to encode?'

$Content = Get-Content -Path $SourceFile -Encoding Byte

$Base64 = [System.Convert]::ToBase64String($Content)

Write-Output 'Outputting the Base64 encoded text to your clipboard'
$Base64 | clip

Write-Output 'Use the following to decode it on the target system'
[System.Convert]::FromBase64String($Base64)