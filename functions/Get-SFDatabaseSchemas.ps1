function Get-SFDatabaseSchemas {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [string]$DataBase,
        [string]$Name,
        [string]$UID,
        [string]$Authenticator = "snowflake",
        [string]$Role,
        [string]$Warehouse,
        [string]$Server
    )
    PROCESS {
        $Schemas = @()
        $ObjectsQuery = "SHOW SCHEMAS IN ACCOUNT;"
        $QueryResults = Get-SFQueryResults -Query $ObjectsQuery -UID $UID -Authenticator $Authenticator -Role $Role -Warehouse $Warehouse -Server $Server -Verbose:$VerbosePreference -Debug:$DebugPreference
        IF ($Name -and $DataBase) {$QueryResults = $QueryResults | Where-Object {$_.name -eq $Name -and $_.database_name -eq $DataBase}}
        ForEach ($Schema in $QueryResults) {
            IF ($Schema.name -ne "INFORMATION_SCHEMA") {
                $SchemaRow = New-Object -TypeName PSObject
                Add-Member -InputObject $SchemaRow -MemberType 'NoteProperty' -Name 'DB' -Value "$($Schema.database_name)"
                Add-Member -InputObject $SchemaRow -MemberType 'NoteProperty' -Name 'SchemaName' -Value "$($Schema.name)"
                $Schemas += $SchemaRow
            }
        }
        RETURN $Schemas

    }
}