function Get-SFWarehouses {
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
    $Warehouses = @()
    $ObjectsQuery = "SHOW WAREHOUSES LIKE '$Name';"
    $QueryResults = Get-SFQueryResults -Query $ObjectsQuery -UID $UID -Authenticator $Authenticator -Role $Role -Warehouse $Warehouse -Server $Server -Verbose:$VerbosePreference -Debug:$DebugPreference
    #$QueryResults
    [PSObject]$Warehouse = @()
    ForEach ($Warehouse in $QueryResults) {
        $Warehouses += $Warehouse.name
    }
    RETURN $Warehouses
}