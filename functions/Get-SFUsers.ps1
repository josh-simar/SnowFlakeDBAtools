function Get-SFUsers {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [string[]]$Name = "%",
        [string]$Schema,
        [string]$UID,
        [string]$Authenticator = "snowflake",
        [string]$Role,
        [string]$Warehouse,
        [string]$Server
    )
    $Users = @()
    $ObjectsQuery = "SHOW USERS LIKE '$Name';"
    $QueryResults = Get-SFQueryResults -Query $ObjectsQuery -UID $UID -Authenticator $Authenticator -Role $Role -Warehouse $Warehouse -Server $Server -Verbose:$VerbosePreference -Debug:$DebugPreference
    #$QueryResults
    [PSObject]$User = @()
    ForEach ($User in $QueryResults) {
        $Users += $User.name
    }
    RETURN $Users
}