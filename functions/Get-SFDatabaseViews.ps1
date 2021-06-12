function Get-SFDatabaseViews {
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
        $Views = @()
        $ObjectsQuery = "SHOW VIEWS IN ACCOUNT;"
        $QueryResults = Get-SFQueryResults -Query $ObjectsQuery -UID $UID -Authenticator $Authenticator -Role $Role -Warehouse $Warehouse -Server $Server -Verbose:$VerbosePreference -Debug:$DebugPreference
        ForEach ($View in $QueryResults) {
            IF ($View.schema_name -ne "INFORMATION_SCHEMA") {
                $ViewRow = New-Object -TypeName PSObject
                Add-Member -InputObject $ViewRow -MemberType 'NoteProperty' -Name 'DB' -Value "$($View.database_name)"
                Add-Member -InputObject $ViewRow -MemberType 'NoteProperty' -Name 'SchemaName' -Value "$($View.schema_name)"
                Add-Member -InputObject $ViewRow -MemberType 'NoteProperty' -Name 'ViewName' -Value "$($View.name)"
                $Views += $ViewRow
            }
        }
        RETURN $Views
    }
}