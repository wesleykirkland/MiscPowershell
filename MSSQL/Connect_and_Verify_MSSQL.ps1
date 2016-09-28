#Test SQL Server Connection
Function Test-SQLConnection {
    #Params
    [CmdletBinding()]
    Param(
    [parameter(Position=0,Mandatory=$true)]
        $ServerInstance,
    [parameter()]
        [System.Management.Automation.PSCredential]$Cred,
    [parameter()]
        [switch]$NoSSPI = $false
    )

    Process {
        if ($NoSSPI -and (!($Cred))) {
            $Cred = Get-Credential
        }

        if ($NoSSPI) {
            Write-Verbose 'Setting SQL to use local credentials'
            $connectionString = "Data Source = $ServerInstance;Initial Catalog=master;User ID = $($cred.UserName);Password = $($cred.GetNetworkCredential().password);"
        } else {
            Write-Verbose 'Setting SQL to use SSPI'
            $connectionString = "Data Source=$Server;Integrated Security=true;Initial Catalog=master;Connect Timeout=3;"
        }

        $sqlConn = New-Object ("Data.SqlClient.SqlConnection") $connectionString
        trap {
            Write-Error "Cannot connect to $Server.";
            exit
        }

        $sqlConn.Open()
        if ($sqlConn.State -eq 'Open') {
            Write-Verbose "Successfully connected to $ServerInstance"
            $sqlConn.Close()
        }
    }
}

Function Run-SQLQuery {
    #Params
    [CmdletBinding()]
    Param(
    [parameter(Position=0,Mandatory=$true)]
        $ServerInstance,
    [parameter(Position=1,Mandatory=$true)]
        $Query,
    [parameter(Position=2,Mandatory=$true)]
        $Database,
    [parameter()]
        [System.Management.Automation.PSCredential]$Cred,
    [parameter()]
        [switch]$NoSSPI = $false
    )

    Process {
        if ($NoSSPI -and (!($Cred))) {
            $Cred = Get-Credential
        }

        #Open SQL Connection
        $SqlConnection = New-Object System.Data.SqlClient.SqlConnection 
        if ($NoSSPI) {
            Write-Verbose 'Setting SQL to use local credentials'
            $SqlConnection.ConnectionString = "Server = $ServerInstance;Database=$Database;User ID=$($cred.UserName);Password=$($cred.GetNetworkCredential().password);"   
        } else {
            Write-Verbose 'Setting SQL to use SSPI'
            $SqlConnection.ConnectionString = "Server=$ServerInstance;Database=$Database;Integrated Security=True"
        }

        $SqlCmd = New-Object System.Data.SqlClient.SqlCommand 
        $SqlCmd.Connection = $SqlConnection 
        $SqlCmd.CommandText = $Query 
        $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter 
        $SqlAdapter.SelectCommand = $SqlCmd 
        $DataSet = New-Object System.Data.DataSet 
        $a=$SqlAdapter.Fill($DataSet) 
        $SqlConnection.Close() 
        $DataSet.Tables[0]
    }
}
