#Function to establish a connection to Netezza
function New-NetezzaSQLConnection {
    #Params
    [CmdletBinding()]
    Param(
    [parameter(Position=0,Mandatory=$true)]
        $ServerInstance,
    [parameter(Position=1,Mandatory=$true)]
        $Database,
    [parameter()]
        [System.Management.Automation.PSCredential]$Cred
    )

    Begin {
        Write-Verbose 'Building the connection string SQLConnection'
        $SQLConnection = New-Object System.Data.Odbc.OdbcConnection        

        $SQLConnection.ConnectionString = "Driver={NetezzaSQL};server=$ServerInstance;UserName=$($Cred.UserName);Password=$($Cred.GetNetworkCredential().Password);Database=$Database"
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

#Function to run Netezza SQL Query
function Run-NetezzaSQLQuery {
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
            $SqlCmd =  $SQLConnection.CreateCommand()
            $SqlCmd.CommandText = $Query
            $SqlAdapter = $SqlCmd.ExecuteReader()

            #Load the results into a datatable
            $DataSet = New-Object System.Data.DataTable
            $DataSet.Load($SqlAdapter)
            $DataSet
        }
    }
}

#Function to close up MSSQL Connection
function Close-NetezzaConnection {
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