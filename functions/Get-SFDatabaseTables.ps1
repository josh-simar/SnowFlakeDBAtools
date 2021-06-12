function Get-SFDatabaseTables {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [PSObject]$Database,
        [PSObject]$Schema,
        [string]$UID,
        [string]$Authenticator = "snowflake",
        [string]$Role,
        [string]$Warehouse,
        [string]$Server
    )
    PROCESS {
        $Tables = @()
        [int]$CurrentPercent = 0
        $CurrentTableCount = 0
        Write-Progress -Activity "Retrieving Account Tables" -Status "$CurrentPercent% Complete:" -PercentComplete $CurrentPercent
        $ObjectsQuery = "SHOW TABLES IN ACCOUNT;"
        $QueryResults = Get-SFQueryResults -Query $ObjectsQuery -UID $UID -Authenticator $Authenticator -Role $Role -Warehouse $Warehouse -Server $Server -Verbose:$VerbosePreference -Debug:$DebugPreference
        ForEach ($Table in $QueryResults) {
            $CurrentTableCount ++
            [int]$CurrentPercent = $CurrentTableCount / $($QueryResults.Count) * 100
            Write-Progress -Activity "Retrieving Account Tables" -Status "$CurrentPercent% Complete:" -PercentComplete $CurrentPercent
            IF ($Table.schema_name -ne "INFORMATION_SCHEMA" -and $Table.kind -eq "TABLE") {
                $TableRow = New-Object -TypeName PSObject
                Add-Member -InputObject $TableRow -MemberType 'NoteProperty' -Name 'DB' -Value "$($Table.database_name)"
                Add-Member -InputObject $TableRow -MemberType 'NoteProperty' -Name 'SchemaName' -Value "$($Table.schema_name)"
                Add-Member -InputObject $TableRow -MemberType 'NoteProperty' -Name 'TableName' -Value "$($Table.name)"
                $Tables += $TableRow
            }
        }
        RETURN $Tables
    }
}