#Function to open up MSSQL Connection
function New-MSSQLConnection {
    #Params
    [CmdletBinding()]
    Param(
    [parameter(Position=0,Mandatory=$true)]
        $ServerInstance,
    [parameter(Position=1,Mandatory=$true)]
        $Database,
    [parameter()]
        [System.Management.Automation.PSCredential]$Cred,
    [parameter()]
        [switch]$NoSSPI = $false
    )

    Begin {
        Write-Verbose 'Building the SQLConnection Object'
        $SQLConnection = New-Object System.Data.SqlClient.SqlConnection

        if ($NoSSPI) {
            Write-Verbose 'Setting SQL to use local credentials'

            if ($NoSSPI -and (!($Cred))) {
                $Cred = Get-Credential
            }

            $SQLConnection.ConnectionString = "Server = $ServerInstance;Database=$Database;User ID=$($cred.UserName);Password=$($cred.GetNetworkCredential().password);"   
        } else {
            Write-Verbose 'Setting SQL to use SSPI'
            $SQLConnection.ConnectionString = "Server=$ServerInstance;Database=$Database;Integrated Security=True"
        }

        Write-Verbose 'Open the SQLConnection'
        Try {
            $SQLConnection.Open()
        } Catch {
            Write-Warning "Unable to open the SQL Connection to $($ServerInstance)\$($Database)"
        }
    }

    Process {
        Write-Verbose 'Returning the SQL connection back to the console'
        return $SQLConnection
    }
}

#Function to run SQL Queries
function Run-SQLQuery {
    #Params
    [CmdletBinding()]
    Param(
    [parameter(Position=0,Mandatory=$true)]
        $SQLConnection,
    [parameter(Position=1,Mandatory=$true)]
        $Query
    )

    Process {
        if ($SQLConnection.State -ne [Data.ConnectionState]::Open) {
            Write-Output "Connection to SQL DB not open"
        } else {
            $SqlCmd = New-Object System.Data.SqlClient.SqlCommand 
            $SqlCmd.Connection = $SqlConnection 
            $SqlCmd.CommandText = $Query 
            $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter 
            $SqlAdapter.SelectCommand = $SqlCmd 
            $DataSet = New-Object System.Data.DataSet 
            $a=$SqlAdapter.Fill($DataSet) 
            $DataSet.Tables[0]
        }
    }
}

#Function to close up MSSQL Connection
function Close-MSSQLConnection {
    #Params
    [CmdletBinding()]
    Param(
    [parameter(Position=0,Mandatory=$true)]
        $SQLConnection
    )

    Process {
        Try {
            $SQLConnection.Close()
            $SQLConnection.Dispose()
        } Catch {
            Write-Warning 'Unable to close SQLConnection'
        }
    }
}