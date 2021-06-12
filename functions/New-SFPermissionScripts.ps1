Function New-SFPermissionScripts {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [PSObject]$Databases,
        [PSObject]$SFAccountObjectPermissions,
        [PSObject]$FileAccountObjectPermissions,
        [PSObject]$FileSchemaPermissions,
        [PSObject]$SFSchemaPermissions,
        [PSObject]$FileSchemaObjectPermissions,
        [PSObject]$SFSchemaObjectPermissions,
        [string]$UID,
        [string]$Authenticator,
        [string]$Role,
        [string]$Warehouse,
        [string]$Server,
        [switch]$WrapInTransaction,
        [switch]$RunAgainstAccount,
        [switch]$CreateGoodFile,
        [string]$GoodFile,
        [string]$GrantFile,
        [string]$RevokeFile,
        [switch]$DebugFiles
    )
    PROCESS {
        $Revoke = @()
        IF ($WrapInTransaction) {$Revoke += "BEGIN TRANSACTION;"}
        $Revoke += ""
        $Revoke += ""
        $Revoke += "// ========================== Account object privileges"
        $Revoke += ""
        $Grant = @()
        IF ($WrapInTransaction) {$Grant += "BEGIN TRANSACTION;"}
        $Grant += ""
        $Grant += ""
        $Grant += "// ========================== Account object privileges"
        $Grant += ""
        $Good = @()
        IF ($CreateGoodFile) {
            IF ($WrapInTransaction) {$Good += "BEGIN TRANSACTION;" }
            $Good += ""
            $Good += ""
            $Good += "// ========================== Account object privileges"
            $Good += ""
        }
        
        $SFAccountObjectPermissions = @()
        $FileAccountObjectPermissions = @()
        $FileSchemaPermissionsFile = @()
        $SFSchemaPermissionsFile = @()
        $FileSchemaObjectPermissionsFile = @()
        $SFSchemaObjectPermissionsFile = @()

        IF ($DebugFiles) {
            Foreach ($Row in $FileSchemaPermissions) {
                    $FileSchemaPermissionsFile += $Row
            }
            Foreach ($Row in $SFSchemaPermissions) {
                    $SFSchemaPermissionsFile += $Row
            }
            Foreach ($Row in $FileSchemaObjectPermissions) {
                    $FileSchemaObjectPermissionsFile += $Row
            }
            Foreach ($Row in $SFSchemaObjectPermissions) {
                    $SFSchemaObjectPermissionsFile += $Row
            }

            $SFAccountObjectPermissions      | Sort-Object -Property @{Expression={$_.Command.Trim()}; Ascending = $True} | Out-File "PS-accountObjectPrivileges-File.sql"
            $FileAccountObjectPermissions    | Sort-Object -Property @{Expression={$_.Command.Trim()}; Ascending = $True} | Out-File "PS-accountObjectPrivileges-DB.sql"
            $FileSchemaPermissionsFile       | Sort-Object -Property @{Expression={$_.Command.Trim()}; Ascending = $True} | Out-File "PS-schemaPrivileges-File.sql"
            $SFSchemaPermissionsFile         | Sort-Object -Property @{Expression={$_.Command.Trim()}; Ascending = $True} | Out-File "PS-schemaPrivileges-DB.sql"
            $FileSchemaObjectPermissionsFile | Sort-Object -Property @{Expression={$_.Command.Trim()}; Ascending = $True} | Out-File "PS-schemaObjectPrivileges-File.sql"
            $SFSchemaObjectPermissionsFile   | Sort-Object -Property @{Expression={$_.Command.Trim()}; Ascending = $True} | Out-File "PS-schemaObjectPrivileges-DB.sql"
        }

        $accountRevoke = @()
        $accountGrant = @()
        IF ($CreateGoodFile) {$accountGood = @()}


        $accountObjectPrivileges = Compare-Object -ReferenceObject $FileAccountObjectPermissions -DifferenceObject $SFAccountObjectPermissions -IncludeEqual
        ForEach ($Line in $accountObjectPrivileges) {
            IF ($Line.SideIndicator -eq "=>") { $accountRevoke += $($Line.InputObject) -replace 'GRANT ', 'REVOKE ' -replace ' TO ', ' FROM ' }
            IF ($Line.SideIndicator -eq "<=") { $accountGrant += "$($Line.InputObject)" }
            IF ($Line.SideIndicator -eq "==" -and $CreateGoodFile) { $accountGood += "$($Line.InputObject)" }
        }

        $accountRevoke = $accountRevoke | Sort-Object -Property @{Expression={$_}; Ascending = $True}
        $accountGrant = $accountGrant   | Sort-Object -Property @{Expression={$_}; Ascending = $True}
        $accountGood = $accountGood     | Sort-Object -Property @{Expression={$_}; Ascending = $True}

        $Revoke += $accountRevoke
        $Grant  += $accountGrant
        IF ($CreateGoodFile) {$Good += $accountGood}

        [PSObject]$Database = @()
        ForEach ($Database in $Databases) {
            [ARRAY]$schemaFilePrivileges = @()
            Foreach ($Row in $FileSchemaPermissions) {
                If ($Row.DB -eq $Database.Name) { $schemaFilePrivileges += $Row.Command.Trim() }
            }
            [Array]$schemaPrivilegesDatabase = @()
            Foreach ($Row in $SFSchemaPermissions) {
                If ($Row.DB -eq $Database.Name) { $schemaPrivilegesDatabase += $Row.Command.Trim() }
            }

            $schemaPrivileges = Compare-Object -ReferenceObject $schemaFilePrivileges -DifferenceObject $schemaPrivilegesDatabase -IncludeEqual

            $SchemaRevoke = @()
            $SchemaGrant = @()
            $SchemaGood = @()

            ForEach ($Line in $schemaPrivileges) {
                IF ($Line.SideIndicator -eq "=>") { $SchemaRevoke += $($Line.InputObject) -replace 'GRANT ', 'REVOKE ' -replace ' TO ', ' FROM ' }
                IF ($Line.SideIndicator -eq "<=") { $SchemaGrant += "$($Line.InputObject)" }
                IF ($Line.SideIndicator -eq "==" -and $CreateGoodFile) { $SchemaGood += "$($Line.InputObject)" }
            }

            $SchemaRevoke = $SchemaRevoke | Sort-Object -Property @{Expression={$_}; Ascending = $True}
            $SchemaGrant = $SchemaGrant | Sort-Object -Property @{Expression={$_}; Ascending = $True}
            IF ($CreateGoodFile) {$SchemaGood = $SchemaGood | Sort-Object -Property @{Expression={$_}; Ascending = $True}}

            New-Variable -Name "SchemaPermissions$($Database.Name)Revoke" -Value $SchemaRevoke -Force
            New-Variable -Name "SchemaPermissions$($Database.Name)Grant" -Value $SchemaGrant -Force
            IF ($CreateGoodFile) {New-Variable -Name "SchemaPermissions$($Database.Name)Good" -Value $SchemaGood -Force}

            [ARRAY]$schemaObjectsFilePrivileges = @()
            Foreach ($Row in $FileSchemaObjectPermissions) {
                If ($Row.DB -eq $Database.Name) { $schemaObjectsFilePrivileges += $Row.Command.Trim() }
            }
            [Array]$schemaObjectsPrivilegesDatabase = @()
            Foreach ($Row in $SFSchemaObjectPermissions) {
                If ($Row.DB -eq $Database.Name) { $schemaObjectsPrivilegesDatabase += $Row.Command.Trim() }
            }

            $schemaObjectsPrivileges = Compare-Object -ReferenceObject $schemaObjectsFilePrivileges -DifferenceObject $schemaObjectsPrivilegesDatabase -IncludeEqual

            $SchemaObjectsRevoke = @()
            $SchemaObjectsGrant = @()
            $SchemaObjectsGood = @()

            ForEach ($Line in $schemaObjectsPrivileges) {
                IF ($Line.SideIndicator -eq "=>") { $SchemaObjectsRevoke += $($Line.InputObject) -replace 'GRANT ', 'REVOKE ' -replace ' TO ', ' FROM ' }
                IF ($Line.SideIndicator -eq "<=") { $SchemaObjectsGrant += "$($Line.InputObject)" }
                IF ($Line.SideIndicator -eq "==") { $SchemaObjectsGood += "$($Line.InputObject)" }
            }

            $SchemaObjectsRevoke = $SchemaObjectsRevoke | Sort-Object -Property @{Expression={$_}; Ascending = $True}
            $SchemaObjectsGrant = $SchemaObjectsGrant | Sort-Object -Property @{Expression={$_}; Ascending = $True}
            IF ($CreateGoodFile) {$SchemaObjectsGood = $SchemaObjectsGood | Sort-Object -Property @{Expression={$_}; Ascending = $True}}

            New-Variable -Name "SchemaObjectsPermissions$($Database.Name)Revoke" -Value $SchemaObjectsRevoke -Force
            New-Variable -Name "SchemaObjectsPermissions$($Database.Name)Grant" -Value $SchemaObjectsGrant -Force
            IF ($CreateGoodFile) {New-Variable -Name "SchemaObjectsPermissions$($Database.Name)Good" -Value $SchemaObjectsGood -Force}
        }

        ForEach ($Database in $Databases) {
            If ($($Database.Shared) -eq "False" ) {
                $Revoke += "// =========================="
                $Revoke += "// ------ Database $($Database.Name)"
                $Revoke += "// =========================="

                $DBRevoke = (Get-Variable -Name "SchemaPermissions$($Database.Name)Revoke").Value

                If ($DBRevoke -ne "") {$Revoke += "// ----- Schema Privileges"}
                $Revoke += $DBRevoke
                $Revoke += ""

                $DBObjectRevoke = (Get-Variable -Name "SchemaObjectsPermissions$($Database.Name)Revoke").Value

                If ($DBObjectRevoke -ne "") {$Revoke += "// ----- Schema Object Privileges"}
                $Revoke += $DBObjectRevoke
                $Revoke += ""

                $Grant += "// =========================="
                $Grant += "// ------ Database $($Database.Name)"
                $Grant += "// =========================="
    
                $DBGrant = (Get-Variable -Name "SchemaPermissions$($Database.Name)Grant").Value
                If ($DBGrant -ne "") {$Grant += "// ----- Schema Privileges"}

                $Grant += $DBGrant
                $Grant += ""

                $DBObjectGrant = (Get-Variable -Name "SchemaObjectsPermissions$($Database.Name)Grant").Value

                If ($DBObjectGrant -ne "") {$Grant += "// ----- Schema Object Privileges"}
                $Grant += $DBObjectGrant
                $Grant += ""

                IF ($CreateGoodFile) {
                    $Good += "// =========================="
                    $Good += "// ------ Database $($Database.Name)"
                    $Good += "// =========================="

                    $DBGood = (Get-Variable -Name "SchemaPermissions$($Database.Name)Good").Value
                    If ($DBGood -ne "") {$Good += "// ----- Schema Privileges"}

                    $Good += $DBGood
                    $Good += ""

                    $DBObjectGood = (Get-Variable -Name "SchemaObjectsPermissions$($Database.Name)Good").Value

                    If ($DBObjectGood -ne "") {$Good += "// ----- Schema Object Privileges"}
                    $Good += $DBObjectGood
                    $Good += ""
                }
            }
        }

        IF ($WrapInTransaction) {$Revoke += "COMMIT;"}
        IF ($WrapInTransaction) {$Grant += "COMMIT;"}
        IF ($WrapInTransaction -and $CreateGoodFile) {$Good += "COMMIT;"}

        $Revoke | Out-File $RevokeFile
        $Grant  | Out-File $GrantFile
        IF ($CreateGoodFile) {$Good | Out-File $GoodFile}

        IF ($RunAgainstAccount) {

            $Revoke = $Revoke | Where-Object {$_ -like "*;"}
            $Grant = $Grant | Where-Object {$_ -like "*;"}

            ForEach ($Row in $Grant) {

                $PWD = [System.Environment]::GetEnvironmentVariable('SNOWSQL_PWD')

                $SnowFlakeConnection = New-Object System.Data.Odbc.OdbcConnection;
                $SnowFlakeConnection.ConnectionString = "Driver={SnowflakeDSIIDriver};UID=$UID;PWD=$PWD;Server=$Server;Database=$Database;Schema=$Schema;Warehouse=$Warehouse;Role=$Role;Authenticator=$Authenticator;";

                $SnowFlakeConnection.Open();
                $cmd = New-object System.Data.Odbc.OdbcCommand($Row,$SnowFlakeConnection)
                $cmd.ExecuteNonQuery() | Out-Null
                $SnowFlakeConnection.Close()
            }
            ForEach ($Row in $Revoke) {

                $RunningCount ++
                [string]$UID = "jsimar"
                [string]$Authenticator = "snowflake"
                [string]$Role = "AccountAdmin"
                [string]$Warehouse = "ADMINISTRATIVE_WH"
                [string]$Server = "dza89750.snowflakecomputing.com"
                [string]$Database = "UTIL_DB"
                [string]$Schema = "INFORMATION_SCHEMA"

                $PWD = [System.Environment]::GetEnvironmentVariable('SNOWSQL_PWD')

                $SnowFlakeConnection = New-Object System.Data.Odbc.OdbcConnection;
                $SnowFlakeConnection.ConnectionString = "Driver={SnowflakeDSIIDriver};UID=$UID;PWD=$PWD;Server=$Server;Database=$Database;Schema=$Schema;Warehouse=$Warehouse;Role=$Role;Authenticator=$Authenticator;";

                $SnowFlakeConnection.Open();
                $cmd = New-object System.Data.Odbc.OdbcCommand($Row,$SnowFlakeConnection)
                $cmd.ExecuteNonQuery() | Out-Null
                $SnowFlakeConnection.Close()
            }
        }
    }
}