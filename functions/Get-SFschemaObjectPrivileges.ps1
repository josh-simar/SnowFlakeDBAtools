function Get-SFschemaObjectPrivileges {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [PSObject]$Databases,
        [PSObject]$Schemas,
        [PSObject]$Tables,
        [PSObject]$Views,
        [PSObject]$Procedures,
        [PSObject]$Sequences,
        [PSObject]$Stages,
        [PSObject]$FileFormats,
        [string]$UID,
        [string]$Authenticator = "snowflake",
        [string]$Role,
        [string]$Warehouse,
        [string]$Server,
        [switch]$SkipTables,
        [switch]$SkipViews,
        [switch]$SkipProcedures,
        [switch]$SkipSequences,
        [switch]$SkipStages,
        [switch]$SkipFileFormats
    )
    PROCESS {
        $SFschemaObjectPrivileges = @()
        $AccountObjectsCount = 0
        If (!($SkipTables))      { $AccountObjectsCount += $($Tables.Count) }
        If (!($SkipViews))       { $AccountObjectsCount += $($Views.Count) }
        If (!($SkipProcedures))  { $AccountObjectsCount += $($Procedures.Count) }
        If (!($SkipSequences))   { $AccountObjectsCount += $($Sequences.Count) }
        If (!($SkipStages))      { $AccountObjectsCount += $($Stages.Count) }
        If (!($SkipFileFormats)) { $AccountObjectsCount += $($FileFormats.Count) }
        Foreach ($Database in $Databases) {
            IF ($Database.Shared -eq "False") {
                $DbSchemas = $Schemas | Where-Object {$_.DB -eq $($Database.Name)};
                ForEach ($Schema in $DbSchemas) {
                    $DBTables = @()
                    $DBViews = @()
                    $DBProcedures = @()
                    $DBSequences = @()
                    $DBStages = @()
                    $DBFileFormats = @()
                    If (!($SkipTables))      { $DBTables += $Tables | Where-Object {$_.DB -eq $($Database.Name) -and $_.SchemaName -eq $($Schema.SchemaName)} }
                    If (!($SkipViews))       { $DBViews += $Views | Where-Object {$_.DB -eq $($Database.Name) -and $_.SchemaName -eq $($Schema.SchemaName)} }
                    If (!($SkipProcedures))  { $DBProcedures += $Procedures | Where-Object {$_.DB -eq $($Database.Name) -and $_.SchemaName -eq $($Schema.SchemaName)} }
                    If (!($SkipSequences))   { $DBSequences += $Sequences | Where-Object {$_.DB -eq $($Database.Name) -and $_.SchemaName -eq $($Schema.SchemaName)} }
                    If (!($SkipStages))      { $DBStages += $Stages | Where-Object {$_.DB -eq $($Database.Name) -and $_.SchemaName -eq $($Schema.SchemaName)} }
                    If (!($SkipFileFormats)) { $DBFileFormats += $FileFormats | Where-Object {$_.DB -eq $($Database.Name) -and $_.SchemaName -eq $($Schema.SchemaName)} }
                    $AllObjectsCount = $($DBTables.Count) + $($DBViews.Count) + $($DBProcedures.Count) + $($DBSequences.Count) + $($DBStages.Count) + $($DBFileFormats.Count)
                    $CurrentObjectCount = 0
                    [int]$CurrentObjectPercent = 0
                    If (!($SkipTables)) {
                        $CurrentTableCount = 0
                        [int]$CurrentPercent = 0
                        ForEach ($Table in $DBTables) {
                            $CurrentTableCount ++
                            $CurrentObjectCount ++
                            $AccountObjectCount ++
                            IF ($($DBTables.Count) -gt 0) {[int]$CurrentPercent = $CurrentTableCount / $($DBTables.Count) * 100}
                            IF ($($DBTables.Count) -gt 0) {[int]$CurrentObjectPercent = $CurrentObjectCount / $($AllObjectsCount) * 100}
                            IF ($($DBTables.Count) -gt 0) {[int]$CurrentAccountPercent = $AccountObjectCount / $($AccountObjectsCount) * 100}
                            Write-Progress       -Activity "All object level database permissions Account : $AccountObjectCount / $AccountObjectsCount" -Status "$CurrentAccountPercent% Complete:" -PercentComplete $CurrentAccountPercent -CurrentOperation "All Account Objects"
                            Write-Progress -Id 1 -Activity "Pulling Current schema object level database permissions for database $($Database.Name) and schema $($Schema.SchemaName) : $CurrentObjectCount / $AllObjectsCount" -Status "$CurrentObjectPercent% Complete:" -PercentComplete $CurrentObjectPercent -CurrentOperation "All Objects"
                            Write-Progress -Id 2 -Activity "Pulling Current table level database permissions for database $($Database.Name) and schema $($Schema.SchemaName) :  $CurrentTableCount / $($DBTables.Count)" -Status "$CurrentPercent% Complete:" -PercentComplete $CurrentPercent -CurrentOperation "Tables"
                            $TableRightsQueryResults = @()
                            $TableRightsQuery = "SHOW GRANTS ON TABLE $($Database.Name).$($Schema.SchemaName).$($Table.TableName);"
                            $TableRightsQueryResults += Get-SFQueryResults -Query $TableRightsQuery -UID $UID -Authenticator $Authenticator -Role $Role -Warehouse $Warehouse -Server $Server -Verbose:$VerbosePreference -Debug:$DebugPreference
                            ForEach ($Row in $TableRightsQueryResults) {
                                If ($Row.granted_to -eq "ROLE" -and $Row.privilege -ne "OWNERSHIP" -and $Row.grantee_name -notin "SYSADMIN","USERADMIN" ) {
                                    $TableRow = New-Object -TypeName PSObject
                                    Add-Member -InputObject $TableRow -MemberType 'NoteProperty' -Name 'DB' -Value "$($Database.name)"
                                    Add-Member -InputObject $TableRow -MemberType 'NoteProperty' -Name 'Command' -Value "GRANT $($Row.privilege) ON TABLE $($Row.name) TO ROLE $($Row.grantee_name);"
                                    $SFschemaObjectPrivileges += $TableRow
                                }
                            }
                        }
                    }
                    IF (!($SkipViews)) {
                        $CurrentViewCount = 0
                        [int]$CurrentPercent = 0
                        ForEach ($View in $DBViews) {
                            $CurrentViewCount ++
                            $CurrentObjectCount ++
                            $AccountObjectCount ++
                            IF ($($DBViews.Count) -gt 0) {[int]$CurrentPercent = $CurrentViewCount / $($DBViews.Count) * 100}
                            IF ($($DBViews.Count) -gt 0) {[int]$CurrentObjectPercent = $CurrentObjectCount / $($AllObjectsCount) * 100}
                            IF ($($DBViews.Count) -gt 0) {[int]$CurrentAccountPercent = $AccountObjectCount / $($AccountObjectsCount) * 100}
                            Write-Progress       -Activity "All object level database permissions Account : $AccountObjectCount / $AccountObjectsCount" -Status "$CurrentAccountPercent% Complete:" -PercentComplete $CurrentAccountPercent -CurrentOperation "All Account Objects"
                            Write-Progress -Id 1 -Activity "Pulling Current schema object level database permissions for database $($Database.Name) and schema $($Schema.SchemaName) : $CurrentObjectCount / $AllObjectsCount" -Status "$CurrentObjectPercent% Complete:" -PercentComplete $CurrentObjectPercent -CurrentOperation "All Objects"
                            Write-Progress -Id 2 -Activity "Pulling Current view level database permissions for database $($Database.Name) and schema $($Schema.SchemaName)" -Status "$CurrentPercent% Complete: $CurrentViewCount / $($DBViews.Count)" -PercentComplete $CurrentPercent -CurrentOperation "Views"
                            $ViewRightsQueryResults = @()
                            $ViewRightsQuery = "SHOW GRANTS ON VIEW $($Database.Name).$($Schema.SchemaName).$($View.ViewName);"
                            $ViewRightsQueryResults += Get-SFQueryResults -Query $ViewRightsQuery -UID $UID -Authenticator $Authenticator -Role $Role -Warehouse $Warehouse -Server $Server -Verbose:$VerbosePreference -Debug:$DebugPreference
                            ForEach ($Row in $ViewRightsQueryResults) {
                                If ($Row.granted_to -eq "ROLE" -and $Row.privilege -ne "OWNERSHIP" -and $Row.grantee_name -notin "SYSADMIN","USERADMIN" ) {
                                    $ViewRow = New-Object -TypeName PSObject
                                    Add-Member -InputObject $ViewRow -MemberType 'NoteProperty' -Name 'DB' -Value "$($Database.name)"
                                    Add-Member -InputObject $ViewRow -MemberType 'NoteProperty' -Name 'Command' -Value "GRANT $($Row.privilege) ON VIEW $($Row.name) TO ROLE $($Row.grantee_name);"
                                    $SFschemaObjectPrivileges += $ViewRow
                                }
                            }
                        }
                    }
                    IF (!($SkipProcedures)) {
                        $CurrentProcedureCount = 0
                        [int]$CurrentPercent = 0
                        ForEach ($Procedure in $DBProcedures) {
                            $CurrentProcedureCount ++
                            $CurrentObjectCount ++
                            $AccountObjectCount ++
                            IF ($($DBProcedures.Count) -gt 0) {[int]$CurrentPercent = $CurrentProcedureCount / $($DBProcedures.Count) * 100}
                            IF ($($DBProcedures.Count) -gt 0) {[int]$CurrentObjectPercent = $CurrentObjectCount / $($AllObjectsCount) * 100}
                            IF ($($DBProcedures.Count) -gt 0) {[int]$CurrentAccountPercent = $AccountObjectCount / $($AccountObjectsCount) * 100}
                            Write-Progress       -Activity "All object level database permissions Account : $AccountObjectCount / $AccountObjectsCount" -Status "$CurrentAccountPercent% Complete:" -PercentComplete $CurrentAccountPercent -CurrentOperation "All Account Objects"
                            Write-Progress -Id 1 -Activity "Pulling Current schema object level database permissions for database $($Database.Name) and schema $($Schema.SchemaName) : $CurrentObjectCount / $AllObjectsCount" -Status "$CurrentObjectPercent% Complete:" -PercentComplete $CurrentObjectPercent -CurrentOperation "All Objects"
                            Write-Progress -Id 2 -Activity "Pulling Current procedure level database permissions for database $($Database.Name) and schema $($Schema.SchemaName): $CurrentProcedureCount / $($DBProcedures.Count)" -Status "$CurrentPercent% Complete" -PercentComplete $CurrentPercent -CurrentOperation "Procedures"
                            $ProcedureRightsQueryResults = @()
                            $ProcedureRightsQuery = "SHOW GRANTS ON $($Procedure.ProgrammingType) $($Database.Name).$($Schema.SchemaName).$($Procedure.ProcedureName);"
                            $ProcedureRightsQueryResults += Get-SFQueryResults -Query $ProcedureRightsQuery -UID $UID -Authenticator $Authenticator -Role $Role -Warehouse $Warehouse -Server $Server -Verbose:$VerbosePreference -Debug:$DebugPreference
                            ForEach ($Row in $ProcedureRightsQueryResults) {
                                If ($Row.granted_to -eq "ROLE" -and $Row.privilege -ne "OWNERSHIP" -and $Row.grantee_name -notin "SYSADMIN","USERADMIN" ) {
                                    $ProcedureRow = New-Object -TypeName PSObject
                                    Add-Member -InputObject $ProcedureRow -MemberType 'NoteProperty' -Name 'DB' -Value "$($Database.name)"
                                    Add-Member -InputObject $ProcedureRow -MemberType 'NoteProperty' -Name 'Command' -Value "GRANT $($Row.privilege) ON $($Procedure.ProgrammingType) $($Database.Name).$($Schema.SchemaName).$($Procedure.ProcedureName)$($Procedure.ProcedureParameters) TO ROLE $($Row.grantee_name);"
                                    $SFschemaObjectPrivileges += $ProcedureRow
                                }
                            }
                        }
                    }
                    IF (!($SkipSequences)) {
                        $CurrentSequenceCount = 0
                        [int]$CurrentPercent = 0
                        ForEach ($Sequence in $DBSequences) {
                            $CurrentSequenceCount ++
                            $CurrentObjectCount ++
                            $AccountObjectCount ++
                            IF ($($DBSequences.Count) -gt 0) {[int]$CurrentPercent = $CurrentSequenceCount / $($DBSequences.Count) * 100}
                            IF ($($DBSequences.Count) -gt 0) {[int]$CurrentObjectPercent = $CurrentObjectCount / $($AllObjectsCount) * 100}
                            IF ($($DBSequences.Count) -gt 0) {[int]$CurrentAccountPercent = $AccountObjectCount / $($AccountObjectsCount) * 100}
                            Write-Progress       -Activity "All object level database permissions Account : $AccountObjectCount / $AccountObjectsCount" -Status "$CurrentAccountPercent% Complete:" -PercentComplete $CurrentAccountPercent -CurrentOperation "All Account Objects"
                            Write-Progress -Id 1 -Activity "Pulling Current schema object level database permissions for database $($Database.Name) and schema $($Schema.SchemaName) : $CurrentObjectCount / $AllObjectsCount" -Status "$CurrentObjectPercent% Complete:" -PercentComplete $CurrentObjectPercent -CurrentOperation "All Objects"
                            Write-Progress -Id 2 -Activity "Pulling Current sequence level database permissions for database $($Database.Name) and schema $($Schema.SchemaName)" -Status "$CurrentPercent% Complete: $CurrentSequenceCount / $($DBSequences.Count)" -PercentComplete $CurrentPercent -CurrentOperation "Sequences"
                            $SequenceRightsQueryResults = @()
                            $SequenceRightsQuery = "SHOW GRANTS ON SEQUENCE $($Database.Name).$($Schema.SchemaName).$($Sequence.SequenceName);"
                            $SequenceRightsQueryResults += Get-SFQueryResults -Query $SequenceRightsQuery -UID $UID -Authenticator $Authenticator -Role $Role -Warehouse $Warehouse -Server $Server -Verbose:$VerbosePreference -Debug:$DebugPreference
                            ForEach ($Row in $SequenceRightsQueryResults) {
                                If ($Row.granted_to -eq "ROLE" -and $Row.privilege -ne "OWNERSHIP" -and $Row.grantee_name -notin "SYSADMIN","USERADMIN" ) {
                                    $SequenceRow = New-Object -TypeName PSObject
                                    Add-Member -InputObject $SequenceRow -MemberType 'NoteProperty' -Name 'DB' -Value "$($Database.name)"
                                    Add-Member -InputObject $SequenceRow -MemberType 'NoteProperty' -Name 'Command' -Value "GRANT $($Row.privilege) ON SEQUENCE $($Row.name) TO ROLE $($Row.grantee_name);"
                                    $SFschemaObjectPrivileges += $SequenceRow
                                }
                            }
                        }
                    }
                    IF (!($SkipStages)) {
                        $CurrentStageCount = 0
                        [int]$CurrentPercent = 0
                        ForEach ($Stage in $DBStages) {
                            $CurrentStageCount ++
                            $CurrentObjectCount ++
                            $AccountObjectCount ++
                            IF ($($DBStages.Count) -gt 0) {[int]$CurrentPercent = $CurrentStageCount / $($DBStages.Count) * 100}
                            IF ($($DBStages.Count) -gt 0) {[int]$CurrentObjectPercent = $CurrentObjectCount / $($AllObjectsCount) * 100}
                            IF ($($DBStages.Count) -gt 0) {[int]$CurrentAccountPercent = $AccountObjectCount / $($AccountObjectsCount) * 100}
                            Write-Progress       -Activity "All object level database permissions Account : $AccountObjectCount / $AccountObjectsCount" -Status "$CurrentAccountPercent% Complete:" -PercentComplete $CurrentAccountPercent -CurrentOperation "All Account Objects"
                            Write-Progress -Id 1 -Activity "Pulling Current schema object level database permissions for database $($Database.Name) and schema $($Schema.SchemaName) : $CurrentObjectCount / $AllObjectsCount" -Status "$CurrentObjectPercent% Complete:" -PercentComplete $CurrentObjectPercent -CurrentOperation "All Objects"
                            Write-Progress -Id 2 -Activity "Pulling Current Stage level database permissions for database $($Database.Name) and schema $($Schema.SchemaName)" -Status "$CurrentPercent% Complete: $CurrentStageCount / $($DBStages.Count)" -PercentComplete $CurrentPercent -CurrentOperation "Stages"
                            $StageRightsQueryResults = @()
                            $StageRightsQuery = "SHOW GRANTS ON STAGE $($Database.Name).$($Schema.SchemaName).""$($Stage.StageName)"";"
                            $StageRightsQueryResults += Get-SFQueryResults -Query $StageRightsQuery -UID $UID -Authenticator $Authenticator -Role $Role -Warehouse $Warehouse -Server $Server -Verbose:$VerbosePreference -Debug:$DebugPreference
                            ForEach ($Row in $StageRightsQueryResults) {
                                If ($Row.granted_to -eq "ROLE" -and $Row.privilege -ne "OWNERSHIP" -and $Row.grantee_name -notin "SYSADMIN","USERADMIN" ) {
                                    $StageRow = New-Object -TypeName PSObject
                                    Add-Member -InputObject $StageRow -MemberType 'NoteProperty' -Name 'DB' -Value "$($Database.name)"
                                    Add-Member -InputObject $StageRow -MemberType 'NoteProperty' -Name 'Command' -Value "GRANT $($Row.privilege) ON STAGE $($Row.name) TO ROLE $($Row.grantee_name);"
                                    $SFschemaObjectPrivileges += $StageRow
                                }
                            }
                        }
                    }
                    IF (!($SkipFileFormats)) {
                        $CurrentFileFormatCount = 0
                        [int]$CurrentPercent = 0
                        ForEach ($FileFormat in $DBFileFormats) {
                            $CurrentFileFormatCount ++
                            $CurrentObjectCount ++
                            $AccountObjectCount ++
                            IF ($($DBFileFormats.Count) -gt 0) {[int]$CurrentPercent = $CurrentFileFormatCount / $($DBFileFormats.Count) * 100}
                            IF ($($DBFileFormats.Count) -gt 0) {[int]$CurrentObjectPercent = $CurrentObjectCount / $($AllObjectsCount) * 100}
                            IF ($($DBFileFormats.Count) -gt 0) {[int]$CurrentAccountPercent = $AccountObjectCount / $($AccountObjectsCount) * 100}
                            Write-Progress       -Activity "All object level database permissions Account : $AccountObjectCount / $AccountObjectsCount" -Status "$CurrentAccountPercent% Complete:" -PercentComplete $CurrentAccountPercent -CurrentOperation "All Account Objects"
                            Write-Progress -Id 1 -Activity "Pulling Current schema object level database permissions for database $($Database.Name) and schema $($Schema.SchemaName) : $CurrentObjectCount / $AllObjectsCount" -Status "$CurrentObjectPercent% Complete:" -PercentComplete $CurrentObjectPercent -CurrentOperation "All Objects"
                            Write-Progress -Id 2 -Activity "Pulling Current File Format level database permissions for database $($Database.Name) and schema $($Schema.SchemaName)" -Status "$CurrentPercent% Complete: $CurrentFileFormatCount / $($DBFileFormats.Count)" -PercentComplete $CurrentPercent -CurrentOperation "FileFormats"
                            $FileFormatRightsQueryResults = @()
                            $FileFormatRightsQuery = "SHOW GRANTS ON FILE FORMAT $($Database.Name).$($Schema.SchemaName).""$($FileFormat.FileFormatName)"";"
                            $FileFormatRightsQueryResults += Get-SFQueryResults -Query $FileFormatRightsQuery -UID $UID -Authenticator $Authenticator -Role $Role -Warehouse $Warehouse -Server $Server -Verbose:$VerbosePreference -Debug:$DebugPreference
                            ForEach ($Row in $FileFormatRightsQueryResults) {
                                If ($Row.granted_to -eq "ROLE" -and $Row.privilege -ne "OWNERSHIP" -and $Row.grantee_name -notin "SYSADMIN","USERADMIN" ) {
                                    $FileFormatRow = New-Object -TypeName PSObject
                                    Add-Member -InputObject $FileFormatRow -MemberType 'NoteProperty' -Name 'DB' -Value "$($Database.name)"
                                    Add-Member -InputObject $FileFormatRow -MemberType 'NoteProperty' -Name 'Command' -Value "GRANT $($Row.privilege) ON FILE FORMAT $($Database.Name).$($Schema.SchemaName).""$($FileFormat.FileFormatName)"" TO ROLE $($Row.grantee_name);"
                                    $SFschemaObjectPrivileges += $FileFormatRow
                                }
                            }
                        }
                    }
                    Write-Progress -Id 2 -Activity "Schema Objects Complete" -Completed
                    Write-Progress -Id 1 -Activity "Pulling Current schema object level database permissions for database $($Database.Name) and schema $($Schema.SchemaName)" -Completed
                }
            }
        }
        RETURN $SFschemaObjectPrivileges
    }
}