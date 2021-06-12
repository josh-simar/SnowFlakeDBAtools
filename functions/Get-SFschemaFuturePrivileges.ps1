function Get-SFschemaFuturePrivileges {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [PSObject]$Databases,
        [PSObject]$Schemas,
        [string]$UID,
        [string]$Authenticator = "snowflake",
        [string]$Role,
        [string]$Warehouse,
        [string]$Server,
        [ValidateSet("TABLE","VIEW","PROCEDURE","FUNCTION","STAGE","SEQUENCE")]
        [string]$ObjectType
    )
    PROCESS {
        $SFschemaFuturePrivileges = @()
        Foreach ($Database in $Databases) {
            IF ($Database.Shared -eq "False") {
                $DbSchemas = $Schemas | Where-Object {$_.DB -eq $($Database.Name)};
                ForEach ($Schema in $DbSchemas) {
                    Write-Progress -Activity "Pulling Current schema level future database schema permissions for database $($Database.Name) and schema $($Schema.SchemaName)"
                    $FutureRightsQueryResults = @()
                    $FutureRightsQuery = "SHOW FUTURE GRANTS IN SCHEMA $($Database.Name).$($Schema.SchemaName);"
                    $FutureRightsQueryResults = Get-SFQueryResults -Query $FutureRightsQuery -Database $($Database.Name) -Schema $Schema -UID $UID -Authenticator $Authenticator -Role $Role -Warehouse $Warehouse -Server $Server -Verbose:$VerbosePreference -Debug:$DebugPreference
                    $FutureRightsQueryResults = $FutureRightsQueryResults | Where-Object {$_.grant_on -eq $ObjectType}
                    ForEach ($Row in $FutureRightsQueryResults) {
                        If ($Row.grant_to -eq "ROLE" -and $Row.privilege -ne "OWNERSHIP" -and $Row.grantee_name -notin "SYSADMIN","USERADMIN" ) {
                            $FutureRow = New-Object -TypeName PSObject
                            Add-Member -InputObject $FutureRow -MemberType 'NoteProperty' -Name 'DB' -Value "$($Database.name)"
                            Add-Member -InputObject $FutureRow -MemberType 'NoteProperty' -Name 'Command' -Value "GRANT $($Row.privilege) ON FUTURE $($Row.grant_on)S IN SCHEMA $($Database.Name).$($Schema.SchemaName) TO ROLE $($Row.grantee_name);"

                            $SFschemaFuturePrivileges += $FutureRow
                        }
                    }
                }
            }
        }
        RETURN $SFschemaFuturePrivileges
    }
}