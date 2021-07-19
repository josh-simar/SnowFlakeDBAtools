function Get-SFDatabaseViews {
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
        $Views = @()
        $ObjectsQuery = "SHOW VIEWS IN ACCOUNT;"
        If ($Database) {$ObjectsQuery = "SHOW VIEWS IN DATABASE $Database;"}
        If ($Database -and $Schema) {$ObjectsQuery = "SHOW VIEWS IN SCHEMA $Database.$Schema;"}
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