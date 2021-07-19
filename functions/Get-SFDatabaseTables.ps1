function Get-SFDatabaseTables {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [string]$Database,
        [string]$Schema,
        [string]$UID,
        [string]$Authenticator = "snowflake",
        [string]$Role,
        [string]$Warehouse,
        [string]$Server
    )
    PROCESS {
        $Tables = @()
        $ObjectsQuery = "SHOW TABLES IN ACCOUNT;"
        If ($Database) {$ObjectsQuery = "SHOW TABLES IN DATABASE $Database;"}
        If ($Database -and $Schema) {$ObjectsQuery = "SHOW TABLES IN SCHEMA $Database.$Schema;"}
        $QueryResults = Get-SFQueryResults -Query $ObjectsQuery -UID $UID -Authenticator $Authenticator -Role $Role -Warehouse $Warehouse -Server $Server -Verbose:$VerbosePreference -Debug:$DebugPreference
        $QueryResults = $QueryResults | Where-Object {$_.schema_name -ne "INFORMATION_SCHEMA" -and $_.kind -eq "TABLE"}
        $Tables = $QueryResults | Select-Object @{Name='DB'; Expression={$_.database_name}},@{Name='SchemaName'; Expression={$_.schema_name}},@{Name='TableName'; Expression={$_.name}}
        RETURN $Tables
    }
}
