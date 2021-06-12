function Get-SFRGBMFileschemaPrivileges {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [PSObject]$SFRGBMFile,
        [PSObject]$Databases,
        [PSObject]$Schemas
    )
    PROCESS {
        $FileSFschemaPrivileges = @()
        Foreach ($schemaPrivilege in $SFRGBMFile.schemaPrivileges) {
            Write-Progress -Activity $schemaPrivilege.Purpose
            ForEach ($Database in $Databases) {
                $schemaPrivilege.Databases = $schemaPrivilege.Databases -replace '%', "*"
                IF ($($Database.Name) -like $($schemaPrivilege.Databases)) {
                    $DbSchemas = $Schemas | Where-Object {$_.DB -eq $($Database.Name)};
                    $schemaPrivilege.Schemas = $schemaPrivilege.Schemas -replace '%', "*"
                    ForEach ($Schema in $DbSchemas) {
                        IF ($($Schema.SchemaName) -like $($schemaPrivilege.Schemas)) {
                            ForEach ($Role in $schemaPrivilege.Roles ) {
                                IF ($Database.Shared -eq "False") {
                                    ForEach ($Privilege in $($schemaPrivilege.Privileges)) {
                                        $SchemaRow = New-Object -TypeName PSObject
                                        Add-Member -InputObject $SchemaRow -MemberType 'NoteProperty' -Name 'DB' -Value "$($Database.name)"
                                        Add-Member -InputObject $SchemaRow -MemberType 'NoteProperty' -Name 'Command' -Value "GRANT $Privilege ON SCHEMA $($Database.Name).$($Schema.SchemaName) TO ROLE $Role;"
                                        Add-Member -InputObject $SchemaRow -MemberType 'NoteProperty' -Name 'Purpose' -Value "$($schemaPrivilege.Purpose)"
                                        $FileSFschemaPrivileges += $SchemaRow
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        RETURN $FileSFschemaPrivileges
    }
}