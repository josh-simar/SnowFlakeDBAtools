function Get-SFRoles {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [string]$UID,
        [string]$Authenticator = "snowflake",
        [string]$Role,
        [string]$Warehouse,
        [string]$Server
    )
    $Roles = @()
    $ObjectsQuery = "SHOW ROLES IN ACCOUNT;"
    $QueryResults = Get-SFQueryResults -Query $ObjectsQuery -UID $UID -Authenticator $Authenticator -Role $Role -Warehouse $Warehouse -Server $Server -Verbose:$VerbosePreference -Debug:$DebugPreference
    [PSObject]$Role = @()
    ForEach ($Role in $QueryResults) {
        $Roles += $Role.name
    }
    RETURN $Roles
}