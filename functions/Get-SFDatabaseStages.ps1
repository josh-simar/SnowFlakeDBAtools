function Get-SFDatabaseStages {
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
        $Stages = @()
        $ObjectsQuery = "SHOW STAGES IN ACCOUNT;"
        $QueryResults = Get-SFQueryResults -Query $ObjectsQuery -UID $UID -Authenticator $Authenticator -Role $Role -Warehouse $Warehouse -Server $Server -Verbose:$VerbosePreference -Debug:$DebugPreference
        ForEach ($Stage in $QueryResults) {
            IF ($Stage.schema_name -ne "INFORMATION_SCHEMA") {
                $StageRow = New-Object -TypeName PSObject
                Add-Member -InputObject $StageRow -MemberType 'NoteProperty' -Name 'DB' -Value "$($Stage.database_name)"
                Add-Member -InputObject $StageRow -MemberType 'NoteProperty' -Name 'SchemaName' -Value "$($Stage.schema_name)"
                Add-Member -InputObject $StageRow -MemberType 'NoteProperty' -Name 'StageType' -Value "$($Stage.type)"
                Add-Member -InputObject $StageRow -MemberType 'NoteProperty' -Name 'StageName' -Value "$($Stage.name)"
                $Stages += $StageRow
            }
        }
        RETURN $Stages
    }
}