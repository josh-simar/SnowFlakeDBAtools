function Get-SFDatabaseTasks {
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
        $Tasks = @()
        $QueryResults = @()
        $ObjectsQuery = "SHOW TASKS IN ACCOUNT;"
        If ($Database) {$ObjectsQuery = "SHOW TASKS IN DATABASE $Database;"}
        If ($Database -and $Schema) {$ObjectsQuery = "SHOW TASKS IN SCHEMA $Database.$Schema;"}
        [Array]$QueryResults = Get-SFQueryResults -Query $ObjectsQuery -UID $UID -Authenticator $Authenticator -Warehouse $Warehouse -Role $Role -Server $Server -Verbose:$VerbosePreference -Debug:$DebugPreference
        [Array]$QueryResults = $QueryResults | Where-Object {$_.schema_name -ne "INFORMATION_SCHEMA"}
        [Array]$QueryResults | Select-Object @{Name='DB'; Expression={$_.database_name}},@{Name='SchemaName'; Expression={$_.schema_name}},@{Name='TaskName'; Expression={$_.name}} -OutVariable Tasks
        [Array]$Streams = [Array]$Streams | Sort-Object -Unique
        RETURN [Array]$Tasks
    }
}