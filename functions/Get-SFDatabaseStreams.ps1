function Get-SFDatabaseStreams {
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
        $Streams = @()
        $QueryResults = @()
        $ObjectsQuery = "SHOW STREAMS IN ACCOUNT;"
        If ($Database) {$ObjectsQuery = "SHOW STREAMS IN DATABASE $Database;"}
        If ($Database -and $Schema) {$ObjectsQuery = "SHOW STREAMS IN SCHEMA $Database.$Schema;"}
        [Array]$QueryResults = Get-SFQueryResults -Query $ObjectsQuery -UID $UID -Authenticator $Authenticator -Warehouse $Warehouse -Role $Role -Server $Server -Verbose:$VerbosePreference -Debug:$DebugPreference
        [Array]$QueryResults = $QueryResults | Where-Object {$_.schema_name -ne "INFORMATION_SCHEMA"}
        [Array]$QueryResults | Select-Object @{Name='DB'; Expression={$_.database_name}},@{Name='SchemaName'; Expression={$_.schema_name}},@{Name='StreamName'; Expression={$_.name}} -OutVariable Streams
        [Array]$Streams = [Array]$Streams | Sort-Object -Unique
        RETURN [Array]$Streams
    }
}