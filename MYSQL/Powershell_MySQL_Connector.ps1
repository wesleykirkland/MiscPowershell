Function Connect-MYSQL {
    Param(
      [Parameter(Mandatory = $true,ParameterSetName = '',ValueFromPipeline = $true)]
      [string]$Query,
      [Parameter(Mandatory=$true)]
      [switch]$MySQLAdminUserName,
      [Parameter(Mandatory=$true)]
      [switch]$MySQLAdminPassword,
      [Parameter(Mandatory=$true)]
      [switch]$MySQLDatabase = "storage",
      [Parameter(Mandatory=$true)]
      [switch]$MySQLHost
      )

    $ConnectionString = "server=" + $MySQLHost + ";port=3306;uid=" + $MySQLAdminUserName + ";pwd=" + $MySQLAdminPassword + ";database="+$MySQLDatabase

    Try {
      [void][System.Reflection.Assembly]::LoadWithPartialName("MySql.Data")
      $Connection = New-Object MySql.Data.MySqlClient.MySqlConnection
      $Connection.ConnectionString = $ConnectionString
      $Connection.Open()

      $Command = New-Object MySql.Data.MySqlClient.MySqlCommand($Query, $Connection)
      $DataAdapter = New-Object MySql.Data.MySqlClient.MySqlDataAdapter($Command)
      $DataSet = New-Object System.Data.DataSet
      $RecordCount = $dataAdapter.Fill($dataSet, "data")
      $DataSet.Tables[0]
      }

    Catch {
      Write-Host "ERROR : Unable to run query : $query `n$Error[0]"
     }

    Finally {
      $Connection.Close()
      }
}