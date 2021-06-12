function Get-SFDatabaseSequences {
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
        $Sequences = @()
        $ObjectsQuery = "SHOW SEQUENCES IN ACCOUNT;"
        $QueryResults = Get-SFQueryResults -Query $ObjectsQuery -UID $UID -Authenticator $Authenticator -Role $Role -Warehouse $Warehouse -Server $Server -Verbose:$VerbosePreference -Debug:$DebugPreference
        ForEach ($Sequence in $QueryResults) {
            IF ($Sequence.schema_name -ne "INFORMATION_SCHEMA") {
                $SequenceRow = New-Object -TypeName PSObject
                Add-Member -InputObject $SequenceRow -MemberType 'NoteProperty' -Name 'DB' -Value "$($Sequence.database_name)"
                Add-Member -InputObject $SequenceRow -MemberType 'NoteProperty' -Name 'SchemaName' -Value "$($Sequence.schema_name)"
                Add-Member -InputObject $SequenceRow -MemberType 'NoteProperty' -Name 'SequenceName' -Value "$($Sequence.name)"
                $Sequences += $SequenceRow
            }
        }
        RETURN $Sequences
    }
}