function Get-SFDatabasePolicies {
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
        $Policies = @()
        $QueryResults = @()
        $ObjectsQuery = "SHOW MASKING POLICIES IN ACCOUNT;"
        If ($Database) {$ObjectsQuery = "SHOW MASKING POLICIES IN DATABASE $Database;"}
        If ($Database -and $Schema) {$ObjectsQuery = "SHOW MASKING POLICIES IN SCHEMA $Database.$Schema;"}
        [Array]$QueryResults = Get-SFQueryResults -Query $ObjectsQuery -UID $UID -Authenticator $Authenticator -Warehouse $Warehouse -Role $Role -Server $Server -Verbose:$VerbosePreference -Debug:$DebugPreference
        $Policies = $QueryResults | Where-Object {$_.schema_name -ne "INFORMATION_SCHEMA"}
        RETURN [Array]$Policies
    }
}

