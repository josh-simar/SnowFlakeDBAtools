function Get-SFDatabaseProcedures {
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
        $Procedures = @()
        $QueryResults = @()
        $ObjectsQuery = "SHOW PROCEDURES IN ACCOUNT;"
        If ($Database) {$ObjectsQuery = "SHOW PROCEDURES IN DATABASE $Database;"}
        If ($Database -and $Schema) {$ObjectsQuery = "SHOW PROCEDURES IN SCHEMA $Database.$Schema;"}
        [Array]$QueryResults = Get-SFQueryResults -Query $ObjectsQuery -UID $UID -Authenticator $Authenticator -Warehouse $Warehouse -Role $Role -Server $Server -Verbose:$VerbosePreference -Debug:$DebugPreference
        [Array]$QueryResults = $QueryResults | Where-Object {$_.schema_name -ne "INFORMATION_SCHEMA"}
        If ($Database) {$QueryResults = $QueryResults | Where-Object {$_.catalog_name}}
        $QueryResultsScrubbed = $QueryResults | Select-Object @{Name='DB'; Expression={$_.catalog_name}},@{Name='SchemaName'; Expression={"$($_.schema_name)"}},@{Name='ProcedureName'; Expression={"$($_.name)"}},@{Name='ProcedureParameters'; Expression={$($($_.arguments).Split('(')[1].Split(')')[0])}}
        $Procedures = $QueryResultsScrubbed | Select-Object @{Name='DB'; Expression={$_.DB}},@{Name='SchemaName'; Expression={"$($_.SchemaName)"}},@{Name='ProcedureName'; Expression={"$($_.ProcedureName)"}},@{Name='ProcedureParameters'; Expression={"($($_.ProcedureParameters))"}}
        RETURN [Array]$Procedures
    }
}

