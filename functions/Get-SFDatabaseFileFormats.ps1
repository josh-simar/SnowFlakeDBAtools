function Get-SFDatabaseFileFormats {
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
        $FileFormats = @()
        $QueryResults = @()
        $ObjectsQuery = "SHOW FILE FORMATS IN ACCOUNT;"
        If ($Database) {$ObjectsQuery = "SHOW FILE FORMATS IN DATABASE $Database;"}
        If ($Database -and $Schema) {$ObjectsQuery = "SHOW FILE FORMATS IN SCHEMA $Database.$Schema;"}
        [Array]$QueryResults = Get-SFQueryResults -Query $ObjectsQuery -UID $UID -Authenticator $Authenticator -Warehouse $Warehouse -Role $Role -Server $Server -Verbose:$VerbosePreference -Debug:$DebugPreference
        [Array]$QueryResults = $QueryResults | Where-Object {$_.schema_name -ne "INFORMATION_SCHEMA"}
        [Array]$QueryResults | Select-Object @{Name='DB'; Expression={$_.database_name}},@{Name='SchemaName'; Expression={$_.schema_name}},@{Name='FileFormatName'; Expression={$_.name}} -OutVariable FileFormats
        RETURN [Array]$FileFormats
    }
}