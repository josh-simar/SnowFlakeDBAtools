function Get-SFDatabaseSequences {
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
        $Sequences = @()
        $ObjectsQuery = "SHOW SEQUENCES IN ACCOUNT;"
        If ($Database) {$ObjectsQuery = "SHOW SEQUENCES IN DATABASE $Database;"}
        If ($Database -and $Schema) {$ObjectsQuery = "SHOW SEQUENCES IN SCHEMA $Database.$Schema;"}
        $QueryResults = Get-SFQueryResults -Query $ObjectsQuery -UID $UID -Authenticator $Authenticator -Role $Role -Warehouse $Warehouse -Server $Server -Verbose:$VerbosePreference -Debug:$DebugPreference
        $QueryResults = $QueryResults | Where-Object {$_.schema_name -ne "INFORMATION_SCHEMA"}
        $Sequences = $QueryResults | Select-Object @{Name='DB'; Expression={$_.database_name}},@{Name='SchemaName'; Expression={$_.schema_name}},@{Name='SequenceName'; Expression={$_.name}}
        RETURN $Sequences
    }
}