function Get-SFQueryResults {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [string]$Query,
        [string]$UID,
        [string]$Authenticator = "snowflake",
        [string]$Role,
        [string]$Warehouse,
        [string]$Server,
        [string]$Database = "UTIL_DB",
        [string]$Schema = "INFORMATION_SCHEMA"
    )
    PROCESS {
        Write-Verbose $Query

        $PWD = [System.Environment]::GetEnvironmentVariable('SNOWSQL_PWD')

        $SnowFlakeConnection = New-Object System.Data.Odbc.OdbcConnection;
        $SnowFlakeConnection.ConnectionString = "Driver={SnowflakeDSIIDriver};UID=$UID;PWD=$PWD;Server=$Server;Database=$Database;Schema=$Schema;Warehouse=$Warehouse;Role=$Role;Authenticator=$Authenticator;";

        Write-Debug "$($SnowFlakeConnection.ConnectionString)"

        $SnowFlakeConnection.Open();
        $cmd = New-object System.Data.Odbc.OdbcCommand($Query,$SnowFlakeConnection)
        $QueryResults = New-Object system.Data.DataSet
        (New-Object system.Data.odbc.odbcDataAdapter($cmd)).fill($QueryResults) | out-null
        $SnowFlakeConnection.Close()
        
        [string[]]$Properties = @()
        Foreach($col in $QueryResults.Tables[0].Columns) {
            $Properties += $col;
        }
        
        $arrayList = New-Object System.Collections.ArrayList
        Foreach($row in $QueryResults.Tables[0]) {
            $arrayList.Add(($row | Select-Object $Properties)) > $null;
        }

        RETURN $arrayList
    }
}