function Get-SFRGBMFileschemaObjectPrivileges {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [PSObject]$SFRGBMFile,
        [PSObject]$Databases,
        [PSObject]$Schemas,
        [PSObject]$Tables,
        [PSObject]$Views,
        [PSObject]$Procedures,
        [PSObject]$Functions,
        [PSObject]$Stages,
        [PSObject]$Sequences,
        [PSObject]$FileFormats,
        [string]$UID,
        [string]$Authenticator = "snowflake",
        [string]$Role,
        [string]$Warehouse,
        [string]$Server,
        [switch]$SkipTables,
        [switch]$SkipViews,
        [switch]$SkipProcedures,
        [switch]$SkipFunctions,
        [switch]$SkipSequences,
        [switch]$SkipStages,
        [switch]$SkipFileFormats,
        [switch]$SkipFutures,
        [string]$Purpose
    )
    PROCESS {
        $FileSFschemaObjectPrivileges = @()
        $schemaObjectPrivileges = $SFRGBMFile.schemaObjectPrivileges
        IF ($Purpose) { $schemaObjectPrivileges = $schemaObjectPrivileges | Where-Object { $_.Purpose -eq $Purpose } }
        Foreach ($schemaObjectPrivilege in $schemaObjectPrivileges) {
            Write-Progress -Activity $schemaObjectPrivilege.Purpose
            ForEach ($Database in $Databases) {
                $schemaObjectPrivilege.Databases = $schemaObjectPrivilege.Databases -replace '%', "*"
                IF ($($Database.Name) -like $($schemaObjectPrivilege.Databases)) {
                    $DbSchemas = $Schemas | Where-Object {$_.DB -eq $($Database.Name)};
                    ForEach ($Schema in $DbSchemas) {
                        $schemaObjectPrivilege.Schemas = $schemaObjectPrivilege.Schemas -replace '%', "*"
                        IF ($($Schema.SchemaName) -like $($schemaObjectPrivilege.Schemas)) {
                            IF (!($SkipTables)) {
                                $schemaObjectPrivilege.Tables = $schemaObjectPrivilege.Tables -replace '%', "*"
                                $DBTables = $Tables | Where-Object {$_.DB -eq $($Database.Name) -and $_.SchemaName -eq $($Schema.SchemaName)};
                                [int]$CurrentPercent = 0
                                $CurrentTableCount = 0
                                ForEach ($Table in $DBTables) {
                                    $CurrentTableCount ++
                                    IF ($($DBTables.Count) -gt 0) {[int]$CurrentPercent = $CurrentTableCount / $($DBTables.Count) * 100}
                                    Write-Progress -Id 1 -Activity "Pulling Wanted table level database permissions for database $($Database.Name) and schema $($Schema.SchemaName) :  $CurrentTableCount / $($DBTables.Count)" -Status "$CurrentPercent% Complete:" -PercentComplete $CurrentPercent -CurrentOperation "Tables"
                                    IF ($($Table.TableName) -like $($schemaObjectPrivilege.Tables)) {
                                        ForEach ($Role in $schemaObjectPrivilege.Roles ) {
                                            IF ($Database.Shared -eq "False") {
                                                ForEach ($Privilege in $($schemaObjectPrivilege.Privileges)) {
                                                    IF ($Privilege -in 'SELECT', 'INSERT', 'UPDATE', 'DELETE', 'TRUNCATE', 'REFERENCES') {
                                                        $TableRow = New-Object -TypeName PSObject
                                                        Add-Member -InputObject $TableRow -MemberType 'NoteProperty' -Name 'DB' -Value "$($Database.name)"
                                                        Add-Member -InputObject $TableRow -MemberType 'NoteProperty' -Name 'Command' -Value "GRANT $Privilege ON TABLE $($Database.Name).$($Schema.SchemaName).$($Table.TableName) TO ROLE $Role;"
                                                        $FileSFschemaObjectPrivileges += $TableRow
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            IF (!($SkipViews)) {
                                $schemaObjectPrivilege.Views = $schemaObjectPrivilege.Views -replace '%', "*"
                                $DBViews = $Views | Where-Object {$_.DB -eq $($Database.Name) -and $_.SchemaName -eq $($Schema.SchemaName)};
                                [int]$CurrentPercent = 0
                                $CurrentViewCount = 0
                                    
                                ForEach ($View in $DBViews) {
                                    $CurrentViewCount ++
                                    IF ($($DBViews.Count) -gt 0) {[int]$CurrentPercent = $CurrentViewCount / $($DBViews.Count) * 100}
                                    Write-Progress -Id 1 -Activity "Pulling Wanted view level database permissions for database $($Database.Name) and schema $($Schema.SchemaName) :  $CurrentViewCount / $($DBViews.Count)" -Status "$CurrentPercent% Complete:" -PercentComplete $CurrentPercent -CurrentOperation "Views"
                                    IF ($($View.name) -like $($schemaObjectPrivilege.Views)) {
                                        ForEach ($Role in $schemaObjectPrivilege.Roles ) {
                                            IF ($Database.Shared -eq "False") {
                                                ForEach ($Privilege in $($schemaObjectPrivilege.Privileges)) {
                                                    If ($Privilege -in 'SELECT', 'REFERENCES') {
                                                        $ViewRow = New-Object -TypeName PSObject
                                                        Add-Member -InputObject $ViewRow -MemberType 'NoteProperty' -Name 'DB' -Value "$($Database.name)"
                                                        Add-Member -InputObject $ViewRow -MemberType 'NoteProperty' -Name 'Command' -Value "GRANT $Privilege ON VIEW $($Database.Name).$($Schema.SchemaName).$($View.ViewName) TO ROLE $Role;"
                                                        
                                                        $FileSFschemaObjectPrivileges += $ViewRow
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            IF (!($SkipProcedures)) {
                                $schemaObjectPrivilege.Procedures = $schemaObjectPrivilege.Procedures -replace '%', "*"
                                $DBProcedures = $Procedures | Where-Object {$_.DB -eq $($Database.Name) -and $_.SchemaName -eq $($Schema.SchemaName)};
                                ForEach ($Procedure in $DBProcedures) {
                                    IF ($Procedure -like $($schemaObjectPrivilege.Procedures)) {
                                        ForEach ($Role in $schemaObjectPrivilege.Roles ) {
                                            IF ($Database.Shared -eq "False") {
                                                ForEach ($Privilege in $($schemaObjectPrivilege.Privileges)) {
                                                    If ($Privilege -in 'USAGE') {
                                                        $ProcedureRow = New-Object -TypeName PSObject
                                                        Add-Member -InputObject $ProcedureRow -MemberType 'NoteProperty' -Name 'DB' -Value "$($Database.name)"
                                                        Add-Member -InputObject $ProcedureRow -MemberType 'NoteProperty' -Name 'Command' -Value "GRANT $Privilege ON PROCEDURE $($Database.Name).$($Schema.SchemaName).$($Procedure.ProcedureName)$($Procedure.ProcedureParameters) TO ROLE $Role;"
                                                        $FileSFschemaObjectPrivileges += $ProcedureRow
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            IF (!($SkipFunctions)) {
                                $schemaObjectPrivilege.Functions = $schemaObjectPrivilege.Functions -replace '%', "*"
                                $DBFunctions = $Functions | Where-Object {$_.DB -eq $($Database.Name) -and $_.SchemaName -eq $($Schema.SchemaName)};
                                ForEach ($Function in $DBFunctions) {
                                    Write-Verbose $Function
                                    IF ($Function -like $($schemaObjectPrivilege.Functions)) {
                                        ForEach ($Role in $schemaObjectPrivilege.Roles ) {
                                            IF ($Database.Shared -eq "False") {
                                                ForEach ($Privilege in $($schemaObjectPrivilege.Privileges)) {
                                                    If ($Privilege -in 'USAGE') {
                                                        $FunctionRow = New-Object -TypeName PSObject
                                                        Add-Member -InputObject $FunctionRow -MemberType 'NoteProperty' -Name 'DB' -Value "$($Database.name)"
                                                        Add-Member -InputObject $FunctionRow -MemberType 'NoteProperty' -Name 'Command' -Value "GRANT $Privilege ON FUNCTION $($Database.Name).$($Schema.SchemaName).$($Function.FunctionName)$($Function.FunctionParameters) TO ROLE $Role;"
                                                        $FileSFschemaObjectPrivileges += $FunctionRow
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            IF (!($SkipSequences)) {
                                $schemaObjectPrivilege.Sequences = $schemaObjectPrivilege.Sequences -replace '%', "*"
                                $DBSequences = $Sequences | Where-Object {$_.DB -eq $($Database.Name) -and $_.SchemaName -eq $($Schema.SchemaName)};
                                ForEach ($Sequence in $DBSequences) {
                                    IF ($Sequence -like $($schemaObjectPrivilege.Sequences)) {
                                        ForEach ($Role in $schemaObjectPrivilege.Roles ) {
                                            IF ($Database.Shared -eq "False") {
                                                ForEach ($Privilege in $($schemaObjectPrivilege.Privileges)) {
                                                    If ($Privilege -in 'USAGE') {
                                                        $SequenceRow = New-Object -TypeName PSObject
                                                        Add-Member -InputObject $SequenceRow -MemberType 'NoteProperty' -Name 'DB' -Value "$($Database.name)"
                                                        Add-Member -InputObject $SequenceRow -MemberType 'NoteProperty' -Name 'Command' -Value "GRANT $Privilege ON SEQUENCE $($Database.Name).$($Schema.SchemaName).$($Sequence.SequenceName) TO ROLE $Role;"
                                                        $FileSFschemaObjectPrivileges += $SequenceRow
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            IF (!($SkipStages)) {
                                $schemaObjectPrivilege.Stages = $schemaObjectPrivilege.Stages -replace '%', "*"
                                $DBStages = $Stages | Where-Object {$_.DB -eq $($Database.Name) -and $_.SchemaName -eq $($Schema.SchemaName)};
                                ForEach ($Stage in $DBStages) {
                                    IF ($Stage -like $($schemaObjectPrivilege.Stages)) {
                                        ForEach ($Role in $schemaObjectPrivilege.Roles ) {
                                            IF ($Database.Shared -eq "False") {
                                                ForEach ($Privilege in $($schemaObjectPrivilege.Privileges)) {
                                                    If ($Privilege -in 'USAGE' -and $($Stage.Stagetype) -eq "EXTERNAL") {
                                                        $StageRow = New-Object -TypeName PSObject
                                                        Add-Member -InputObject $StageRow -MemberType 'NoteProperty' -Name 'DB' -Value "$($Database.name)"
                                                        Add-Member -InputObject $StageRow -MemberType 'NoteProperty' -Name 'Command' -Value "GRANT $Privilege ON STAGE $($Database.Name).$($Schema.SchemaName).$($Stage.StageName) TO ROLE $Role;"
                                                        $FileSFschemaObjectPrivileges += $StageRow
                                                    }
                                                    If ($Privilege -in 'READ', 'WRITE' -and $($Stage.Stagetype) -eq "INTERNAL") {
                                                        $StageRow = New-Object -TypeName PSObject
                                                        Add-Member -InputObject $StageRow -MemberType 'NoteProperty' -Name 'DB' -Value "$($Database.name)"
                                                        Add-Member -InputObject $StageRow -MemberType 'NoteProperty' -Name 'Command' -Value "GRANT $Privilege ON STAGE $($Database.Name).$($Schema.SchemaName).$($Stage.StageName) TO ROLE $Role;"
                                                        $FileSFschemaObjectPrivileges += $StageRow
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            IF (!($SkipFileFormats)) {
                                $schemaObjectPrivilege.FileFormats = $schemaObjectPrivilege.FileFormats -replace '%', "*"
                                $DBFileFormats = $FileFormats | Where-Object {$_.DB -eq $($Database.Name) -and $_.SchemaName -eq $($Schema.SchemaName)};
                                ForEach ($FileFormat in $DBFileFormats) {
                                    IF ($FileFormat -like $($schemaObjectPrivilege.FileFormats)) {
                                        ForEach ($Role in $schemaObjectPrivilege.Roles ) {
                                            IF ($Database.Shared -eq "False") {
                                                ForEach ($Privilege in $($schemaObjectPrivilege.Privileges)) {
                                                    If ($Privilege -in 'USAGE' ) {
                                                        $FileFormatRow = New-Object -TypeName PSObject
                                                        Add-Member -InputObject $FileFormatRow -MemberType 'NoteProperty' -Name 'DB' -Value "$($Database.name)"
                                                        Add-Member -InputObject $FileFormatRow -MemberType 'NoteProperty' -Name 'Command' -Value "GRANT $Privilege ON FILE FORMAT $($Database.Name).$($Schema.SchemaName).""$($FileFormat.FileFormatName)"" TO ROLE $Role;"
                                                        $FileSFschemaObjectPrivileges += $FileFormatRow
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            IF (!($SkipFutures)) {
                                IF ($schemaObjectPrivilege.FutureTables) {
                                    ForEach ($Role in $schemaObjectPrivilege.Roles ) {
                                        IF ($Database.Shared -eq "False") {
                                            ForEach ($Privilege in $($schemaObjectPrivilege.Privileges)) {
                                                IF ($Privilege -in 'SELECT', 'INSERT', 'UPDATE', 'DELETE', 'TRUNCATE', 'REFERENCES') {
                                                    $FutureRow = New-Object -TypeName PSObject
                                                    Add-Member -InputObject $FutureRow -MemberType 'NoteProperty' -Name 'DB' -Value "$($Database.name)"
                                                    Add-Member -InputObject $FutureRow -MemberType 'NoteProperty' -Name 'Command' -Value "GRANT $Privilege ON FUTURE TABLES IN SCHEMA $($Database.Name).$($Schema.SchemaName) TO ROLE $Role;"

                                                    $FileSFschemaObjectPrivileges += $FutureRow
                                                }
                                            }
                                        }
                                    }
                                }
                                IF ($schemaObjectPrivilege.FutureViews) {
                                    ForEach ($Role in $schemaObjectPrivilege.Roles ) {
                                        IF ($Database.Shared -eq "False") {
                                            ForEach ($Privilege in $($schemaObjectPrivilege.Privileges)) {
                                                IF ($Privilege -in 'SELECT', 'REFERENCES') {
                                                    $FutureRow = New-Object -TypeName PSObject
                                                    Add-Member -InputObject $FutureRow -MemberType 'NoteProperty' -Name 'DB' -Value "$($Database.name)"
                                                    Add-Member -InputObject $FutureRow -MemberType 'NoteProperty' -Name 'Command' -Value "GRANT $Privilege ON FUTURE VIEWS IN SCHEMA $($Database.Name).$($Schema.SchemaName) TO ROLE $Role;"

                                                    $FileSFschemaObjectPrivileges += $FutureRow
                                                }
                                            }
                                        }
                                    }
                                }
                                IF ($schemaObjectPrivilege.FutureProcedures) {
                                    ForEach ($Role in $schemaObjectPrivilege.Roles ) {
                                        IF ($Database.Shared -eq "False") {
                                            ForEach ($Privilege in $($schemaObjectPrivilege.Privileges)) {
                                                IF ($Privilege -in 'USAGE') {
                                                    $FutureRow = New-Object -TypeName PSObject
                                                    Add-Member -InputObject $FutureRow -MemberType 'NoteProperty' -Name 'DB' -Value "$($Database.name)"
                                                    Add-Member -InputObject $FutureRow -MemberType 'NoteProperty' -Name 'Command' -Value "GRANT $Privilege ON FUTURE PROCEDURES IN SCHEMA $($Database.Name).$($Schema.SchemaName) TO ROLE $Role;"
                                                    $FileSFschemaObjectPrivileges += $FutureRow
                                                    $FutureRow = New-Object -TypeName PSObject
                                                    Add-Member -InputObject $FutureRow -MemberType 'NoteProperty' -Name 'DB' -Value "$($Database.name)"
                                                    Add-Member -InputObject $FutureRow -MemberType 'NoteProperty' -Name 'Command' -Value "GRANT $Privilege ON FUTURE FUNCTIONS IN SCHEMA $($Database.Name).$($Schema.SchemaName) TO ROLE $Role;"
                                                    $FileSFschemaObjectPrivileges += $FutureRow
                                                }
                                            }
                                        }
                                    }
                                }
                                IF ($schemaObjectPrivilege.FutureStages) {
                                    ForEach ($Role in $schemaObjectPrivilege.Roles ) {
                                        IF ($Database.Shared -eq "False") {
                                            ForEach ($Privilege in $($schemaObjectPrivilege.Privileges)) {
                                                IF ($Privilege -in 'USAGE', 'READ', 'WRITE') {
                                                    $FutureRow = New-Object -TypeName PSObject
                                                    Add-Member -InputObject $FutureRow -MemberType 'NoteProperty' -Name 'DB' -Value "$($Database.name)"
                                                    Add-Member -InputObject $FutureRow -MemberType 'NoteProperty' -Name 'Command' -Value "GRANT $Privilege ON FUTURE STAGES IN SCHEMA $($Database.Name).$($Schema.SchemaName) TO ROLE $Role;"
                                                    $FileSFschemaObjectPrivileges += $FutureRow
                                                }
                                            }
                                        }
                                    }
                                }
                                IF ($schemaObjectPrivilege.FutureSequences) {
                                    ForEach ($Role in $schemaObjectPrivilege.Roles ) {
                                        IF ($Database.Shared -eq "False") {
                                            ForEach ($Privilege in $($schemaObjectPrivilege.Privileges)) {
                                                IF ($Privilege -in 'USAGE') {
                                                    $FutureRow = New-Object -TypeName PSObject
                                                    Add-Member -InputObject $FutureRow -MemberType 'NoteProperty' -Name 'DB' -Value "$($Database.name)"
                                                    Add-Member -InputObject $FutureRow -MemberType 'NoteProperty' -Name 'Command' -Value "GRANT $Privilege ON FUTURE SEQUENCES IN SCHEMA $($Database.Name).$($Schema.SchemaName) TO ROLE $Role;"
                                                    $FileSFschemaObjectPrivileges += $FutureRow
                                                }
                                            }
                                        }
                                    }
                                }
                                IF ($schemaObjectPrivilege.FutureFileFormats) {
                                    ForEach ($Role in $schemaObjectPrivilege.Roles ) {
                                        IF ($Database.Shared -eq "False") {
                                            ForEach ($Privilege in $($schemaObjectPrivilege.Privileges)) {
                                                IF ($Privilege -in 'USAGE') {
                                                    $FutureRow = New-Object -TypeName PSObject
                                                    Add-Member -InputObject $FutureRow -MemberType 'NoteProperty' -Name 'DB' -Value "$($Database.name)"
                                                    Add-Member -InputObject $FutureRow -MemberType 'NoteProperty' -Name 'Command' -Value "GRANT $Privilege ON FUTURE FILE FORMATS IN SCHEMA $($Database.Name).$($Schema.SchemaName) TO ROLE $Role;"
                                                    $FileSFschemaObjectPrivileges += $FutureRow
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        RETURN $FileSFschemaObjectPrivileges
    }
}