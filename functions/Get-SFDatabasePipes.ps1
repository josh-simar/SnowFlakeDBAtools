function Get-SFDatabasePipes {
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
        $Pipes = @()
        $QueryResults = @()
        $ObjectsQuery = "SHOW PIPES IN ACCOUNT;"
        If ($Database) {$ObjectsQuery = "SHOW PIPES IN DATABASE $Database;"}
        If ($Database -and $Schema) {$ObjectsQuery = "SHOW PIPES IN SCHEMA $Database.$Schema;"}
        [Array]$QueryResults = Get-SFQueryResults -Query $ObjectsQuery -UID $UID -Authenticator $Authenticator -Warehouse $Warehouse -Role $Role -Server $Server -Verbose:$VerbosePreference -Debug:$DebugPreference
        [Array]$QueryResults = $QueryResults | Where-Object {$_.schema_name -ne "INFORMATION_SCHEMA"}
        [Array]$QueryResults | Select-Object @{Name='DB'; Expression={$_.database_name}},@{Name='SchemaName'; Expression={$_.schema_name}},@{Name='PipeName'; Expression={$_.name}} -OutVariable Pipes
        RETURN [Array]$Pipes
    }
}