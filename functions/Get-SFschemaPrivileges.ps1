function Get-SFschemaPrivileges {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [PSObject]$Databases,
        [PSObject]$Schemas,
        [string]$UID,
        [string]$Authenticator = "snowflake",
        [string]$Role,
        [string]$Warehouse,
        [string]$Server
    )
    PROCESS {
        $SchemaRightsQueryResultsFormatted = @()
        Foreach ($Database in $Databases) {
            Write-Progress -Activity "Pulling Current schema level database permissions for database $($Database.Name)"
            IF ($Database.Shared -eq "False") {
                $DbSchemas = $Schemas | Where-Object {$_.DB -eq $($Database.Name)};
                ForEach ($Schema in $DbSchemas) {
                    $SchemaRightsQueryResults = @()
                    $SchemaRightsQuery = "SHOW GRANTS ON SCHEMA $($Database.Name).$($Schema.SchemaName);"
                    $SchemaRightsQueryResults += Get-SFQueryResults -Query $SchemaRightsQuery -UID $UID -Authenticator $Authenticator -Role $Role -Warehouse $Warehouse -Server $Server -Verbose:$VerbosePreference -Debug:$DebugPreference
                    ForEach ($Row in $SchemaRightsQueryResults) {
                        If ($Row.granted_to -eq "ROLE" -and $Row.privilege -ne "OWNERSHIP" -and $Row.grantee_name -notin "SYSADMIN","USERADMIN" ) {
                            $SchemaRow = New-Object -TypeName PSObject
                            Add-Member -InputObject $SchemaRow -MemberType 'NoteProperty' -Name 'DB' -Value "$($Database.name)"
                            Add-Member -InputObject $SchemaRow -MemberType 'NoteProperty' -Name 'Command' -Value "GRANT $($Row.privilege) ON SCHEMA $($Row.name) TO ROLE $($Row.grantee_name);"

                            $SchemaRightsQueryResultsFormatted += $SchemaRow
                        }
                    }
                }
            }
        }
        RETURN $SchemaRightsQueryResultsFormatted
    }
}