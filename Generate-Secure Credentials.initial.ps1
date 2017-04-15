<#
.Synopsis
   Creates a script that will genereate more secure credentials
.DESCRIPTION
   Gets the credentials and converts the secure string password to an encrypted standard string.
   Creates a script that will decrypt the base-64 string and set the credentials to a variable.
   The output script will be opened in a new ISE tab.
.EXAMPLE
   Generate-SecureCredentials
.EXAMPLE
   Get-Credential | Generate-SecureCredentials
.EXAMPLE
   $cred = Get-Credential
   Generate-SecureCredentials -Credentials $cred
#>
function Generate-SecureCredentials
{
    [CmdletBinding()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
        [System.Management.Automation.CredentialAttribute()]
        $Credentials
    )

    Begin
    {
    }
    Process
    {
        $pass = $Credentials.Password
        $user = $Credentials.UserName

        # create random encryption key
        $key = 1..32 | ForEach-Object { Get-Random -Maximum 256 }

        # encrypt password with key
        $passencrypted = $pass | ConvertFrom-SecureString -Key $key

        # turn key and password into text representations
        $secret = -join ($key | ForEach-Object { '{0:x2}' -f $_ })
        $secret += $passencrypted

        # create code
        $code  = '$i = ''{0}'';' -f $secret 
        $code += '$cred = New-Object PSCredential(''' 
        $code += $user + ''', (ConvertTo-SecureString $i.SubString(64)'
        $code += ' -k ($i.SubString(0,64) -split "(?<=\G[0-9a-f]{2})(?=.)" |'
        $code += ' % { [Convert]::ToByte($_,16) })))'
    }
    End
    {
        # write new script
        $editor = $psise.CurrentPowerShellTab.files.Add().Editor
        $editor.InsertText($code)
        $editor.SetCaretPosition(1,1) 
    }
}