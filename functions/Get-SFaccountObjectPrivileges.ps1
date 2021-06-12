function Get-SFaccountObjectPrivileges {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [PSObject]$Databases,
        [PSObject]$Warehouses,
        [string]$UID,
        [string]$Authenticator = "snowflake",
        [string]$Role,
        [string]$Warehouse,
        [string]$Server
    )
    PROCESS {
        If ($Databases) {
            [int]$CurrentPercent = 0
            Write-Progress -Activity "Pulling Current account level database permissions" -Status "$CurrentPercent% Complete:" -PercentComplete $CurrentPercent
            $DatabaseRightsQueryResultsFormatted = @()
            $CurrentDatabaseCount = 0
            Foreach ($Database in $Databases) {
                $CurrentDatabaseCount ++
                [int]$CurrentPercent = $CurrentDatabaseCount / $($Databases.Count) * 100
                Write-Progress -Activity "Pulling Current account level database permissions" -Status "$CurrentPercent% Complete:" -PercentComplete $CurrentPercent
                $DatabaseRightsQueryResults = @()
                $DatabaseRightsQuery = "SHOW GRANTS ON DATABASE $($Database.Name);"
                $DatabaseRightsQueryResults += Get-SFQueryResults -Query $DatabaseRightsQuery -UID $UID -Authenticator $Authenticator -Role $Role -Warehouse $Warehouse -Server $Server -Verbose:$VerbosePreference -Debug:$DebugPreference
                ForEach ($Row in $DatabaseRightsQueryResults) {
                    If ($Row.granted_to -eq "ROLE" -and $Row.privilege -ne "OWNERSHIP") {
                        If ($($Database.Shared) -eq "True") { $Row.privilege = "IMPORTED PRIVILEGES"}
                        $DatabaseRightsQueryResultsFormatted += "GRANT $($Row.privilege) ON DATABASE $($Row.name) TO ROLE $($Row.grantee_name);"
                    }
                }
            }
            
        }
        IF ($Warehouses) {
            [int]$CurrentPercent = 0
            Write-Progress -Activity "Pulling Current account level warehouse permissions" -Status "$CurrentPercent% Complete:" -PercentComplete $CurrentPercent
            $WarehouseRightsQueryResultsFormatted = @()
            $CurrentWarehouseCount = 0
            Foreach ($Warehouse in $Warehouses) {
                $CurrentWarehouseCount ++
                [int]$CurrentPercent = $CurrentWarehouseCount / $($Warehouses.Count) * 100
                Write-Progress -Activity "Pulling Current account level warehouse permissions" -Status "$CurrentPercent% Complete:" -PercentComplete $CurrentPercent
                $WarehousesRightsQueryResults = @()
                $WarehousesRightsQuery = "SHOW GRANTS ON WAREHOUSE $Warehouse;"
                $WarehouseRightsQueryResults = Get-SFQueryResults -Query $WarehousesRightsQuery -UID $UID -Authenticator $Authenticator -Role $Role -Warehouse $Warehouse -Server $Server -Verbose:$VerbosePreference -Debug:$DebugPreference
                ForEach ($Row in $WarehouseRightsQueryResults) {
                    If ($Row.granted_to -eq "ROLE" -and $Row.privilege -ne "OWNERSHIP") {
                        $WarehouseRightsQueryResultsFormatted += "GRANT $($Row.privilege) ON WAREHOUSE $($Row.name) TO ROLE $($Row.grantee_name);"
                    }
                }
            }
        }
        $accountRights = @()
        $accountRights += $DatabaseRightsQueryResultsFormatted
        $accountRights += $WarehouseRightsQueryResultsFormatted
        RETURN $accountRights
    }
}