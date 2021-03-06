function Get-SFrbgmPermissions {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [string]$UID,
        [string]$Authenticator,
        [string]$Role,
        [string]$Warehouse,
        [string]$Server,
        [string]$PermissionFile,
        [switch]$WrapInTransaction,
        [switch]$RunAgainstAccount,
        [switch]$CreateGoodFile,
        [string]$GoodFile = "PS-Good.sql",
        [string]$GrantFile = "PS-Grants.sql",
        [string]$RevokeFile = "PS-Revokes.sql",
        [switch]$DebugFiles,
        [switch]$SkipTables,
        [switch]$SkipViews,
        [switch]$SkipProcedures,
        [switch]$SkipFileFormats,
        [switch]$SkipFutures
    )
    PROCESS {

    $ConnectionHash = @{
        UID = $UID
        Authenticator = $Authenticator
        Role = $Role
        Warehouse = $Warehouse
        Server = $Server
    }

    $accountObjectPrivileges = @()
    $AccountDatabases = @()
    $AccountWarehouses = @()
    $LogFile = @()
    $SFRGBMFile = Get-Content -Raw -Path $PermissionFile -Force | ConvertFrom-Json

    Write-Progress -Activity "Retrieving Account Databases"
    $AccountDatabases = Get-SFDatabases @ConnectionHash -Verbose:$VerbosePreference -Debug:$DebugPreference
    $AccountSharedDatabases = $AccountDatabases | Where-Object {$_.Shared -eq "True"} | Select-Object Name
    Write-Progress -Activity "Retrieving Account Warehouses"
    $AccountWarehouses = Get-SFWarehouses @ConnectionHash -Verbose:$VerbosePreference -Debug:$DebugPreference
    Write-Progress -Activity "Retrieving Account Schemas"
    $AccountSchemas = Get-SFDatabaseSchemas @ConnectionHash -Verbose:$VerbosePreference -Debug:$DebugPreference
    Write-Progress -Activity "Retrieving Account Tables"
    $AccountTables = Get-SFDatabaseTables @ConnectionHash -Verbose:$VerbosePreference -Debug:$DebugPreference
    Write-Progress -Activity "Retrieving Account Views"
    $AccountViews = Get-SFDatabaseViews @ConnectionHash -Verbose:$VerbosePreference -Debug:$DebugPreference
    Write-Progress -Activity "Retrieving Account Procedures"
    $AccountProcedures = Get-SFDatabaseProcedures @ConnectionHash -Verbose:$VerbosePreference -Debug:$DebugPreference
    Write-Progress -Activity "Retrieving Account Functions"
    $AccountFunctions = Get-SFDatabaseFunctions @ConnectionHash -Verbose:$VerbosePreference -Debug:$DebugPreference
    Write-Progress -Activity "Retrieving Account Sequences"
    $AccountSequences = Get-SFDatabaseSequences @ConnectionHash -Verbose:$VerbosePreference -Debug:$DebugPreference
    Write-Progress -Activity "Retrieving Account Stages"
    $AccountStages = Get-SFDatabaseStages @ConnectionHash -Verbose:$VerbosePreference -Debug:$DebugPreference
    Write-Progress -Activity "Retrieving Account Stages"
    $AccountFileFormats = Get-SFDatabaseFileFormats @ConnectionHash -Verbose:$VerbosePreference -Debug:$DebugPreference
    Write-Progress -Activity "Retrieving Account Roles"
    $AccountRoles = Get-SFRoles @ConnectionHash -Verbose:$VerbosePreference -Debug:$DebugPreference

    $NonSystemAccountRoles = $AccountRoles | Where-Object {$_ -notin @('ACCOUNTADMIN','SECURITYADMIN','SYSADMIN','USERADMIN')}

    Write-Progress -Activity "Retrieving Role Rights"
    $RoleRights = Get-SFRoleRights -Roles $NonSystemAccountRoles @ConnectionHash

    IF ($RoleRights -ne "") {
        $AccountTablesConcat = @()
        ForEach ($Table in $AccountTables) { $AccountTablesConcat += "$($Table.DB).$($Table.SchemaName).$($Table.TableName)" }

        $SFAccountObjectPermissions = $RoleRights | Where-Object { $_.Level -eq "accountObject" }
        Foreach ($SFAccountObjectPermission in $SFAccountObjectPermissions) {
            IF ($($SFAccountObjectPermission.DB) -in $($AccountSharedDatabases.Name)) {
                $SFAccountObjectPermission.Command = $SFAccountObjectPermission.Command -replace 'USAGE', 'IMPORTED PRIVILEGES'
            }
        }

        $SFAccountObjectPermissions = $SFAccountObjectPermissions | Select -ExpandProperty Command
        $SFSchemaPermissions = $RoleRights | Where-Object { $_.Level -eq "schema" -and $_.DB -ne "SNOWFLAKE" } | Select-Object DB,Command 
        $SFSchemaObjectPermissionsOthers = $RoleRights | Where-Object { $_.Level -eq "schemaObject" -and $_.DB -ne "SNOWFLAKE" -and $_.ObjectType -ne "TABLE" } | Select-Object DB,Command
        $SFSchemaObjectPermissionsTables = $RoleRights | Where-Object { $_.Level -eq "schemaObject" -and $_.DB -ne "SNOWFLAKE" -and $_.ObjectType -eq "TABLE" -and $_.ObjectName -in $AccountTablesConcat } | Select-Object DB,Command
        $SFSchemaObjectPermissions = $SFSchemaObjectPermissionsOthers
        $SFSchemaObjectPermissions += $SFSchemaObjectPermissionsTables
    } Else {
        $SFAccountObjectPermissions = Get-SFaccountObjectPrivileges -Databases $AccountDatabases -Warehouses $AccountWarehouses @ConnectionHash -Verbose:$VerbosePreference -Debug:$DebugPreference
        $SFSchemaPermissions = Get-SFschemaPrivileges -Databases $AccountDatabases -Schemas $AccountSchemas @ConnectionHash -Verbose:$VerbosePreference -Debug:$DebugPreference
        $SFSchemaObjectPermissions = Get-SFschemaObjectPrivileges -Databases $AccountDatabases -Schemas $AccountSchemas -Tables $AccountTables -Views $AccountViews -Procedures $AccountProcedures -Functions $AccountFunctions -Sequences $AccountSequences -Stages $AccountStages -FileFormats $AccountFileFormats -SkipTables:$SkipTables -SkipViews:$SkipViews -SkipProcedures:$SkipProcedures -SkipSequences:$SkipSequences -SkipStages:$SkipStages -SkipFileFormats:$SkipFileFormats @ConnectionHash -Verbose:$VerbosePreference -Debug:$DebugPreference
    }
    IF (!($SkipFutures)) {
        $SFSchemaFutureTablePermissions = Get-SFschemaFuturePrivileges -Databases $AccountDatabases -Schemas $AccountSchemas @ConnectionHash -ObjectType TABLE -Verbose:$VerbosePreference -Debug:$DebugPreference
        $SFSchemaFutureViewPermissions = Get-SFschemaFuturePrivileges -Databases $AccountDatabases -Schemas $AccountSchemas @ConnectionHash -ObjectType VIEW -Verbose:$VerbosePreference -Debug:$DebugPreference
        $SFSchemaFutureProcedurePermissions = Get-SFschemaFuturePrivileges -Databases $AccountDatabases -Schemas $AccountSchemas @ConnectionHash -ObjectType PROCEDURE -Verbose:$VerbosePreference -Debug:$DebugPreference
        $SFSchemaFutureFunctionPermissions = Get-SFschemaFuturePrivileges -Databases $AccountDatabases -Schemas $AccountSchemas @ConnectionHash -ObjectType FUNCTION -Verbose:$VerbosePreference -Debug:$DebugPreference
        $SFSchemaFutureStagePermissions = Get-SFschemaFuturePrivileges -Databases $AccountDatabases -Schemas $AccountSchemas @ConnectionHash -ObjectType STAGE -Verbose:$VerbosePreference -Debug:$DebugPreference
        $SFSchemaFutureSequencePermissions = Get-SFschemaFuturePrivileges -Databases $AccountDatabases -Schemas $AccountSchemas @ConnectionHash -ObjectType SEQUENCE -Verbose:$VerbosePreference -Debug:$DebugPreference
        $SFSchemaFutureFileFormatPermissions = Get-SFschemaFuturePrivileges -Databases $AccountDatabases -Schemas $AccountSchemas @ConnectionHash -ObjectType FILE_FORMAT -Verbose:$VerbosePreference -Debug:$DebugPreference
    }

    $SFSchemaObjectPermissions += $SFSchemaFutureTablePermissions
    $SFSchemaObjectPermissions += $SFSchemaFutureViewPermissions
    $SFSchemaObjectPermissions += $SFSchemaFutureProcedurePermissions
    $SFSchemaObjectPermissions += $SFSchemaFutureFunctionPermissions
    $SFSchemaObjectPermissions += $SFSchemaFutureStagePermissions
    $SFSchemaObjectPermissions += $SFSchemaFutureSequencePermissions
    $SFSchemaObjectPermissions += $SFSchemaFutureFileFormatPermissions

    $FileAccountObjectPermissions = Get-SFRGBMFileaccountObjectPrivileges -SFRGBMFile $SFRGBMFile -Databases $AccountDatabases -Warehouses $AccountWarehouses -Verbose:$VerbosePreference -Debug:$DebugPreference
    $FileSchemaPermissions = Get-SFRGBMFileschemaPrivileges -SFRGBMFile $SFRGBMFile -Schemas $AccountSchemas -Databases $AccountDatabases -Verbose:$VerbosePreference -Debug:$DebugPreference
    $FileSchemaObjectPermissions = Get-SFRGBMFileschemaObjectPrivileges -Databases $AccountDatabases -Schemas $AccountSchemas -Tables $AccountTables -Views $AccountViews -Procedures $AccountProcedures -Functions $AccountFunctions -Sequences $AccountSequences -Stages $AccountStages -FileFormats $AccountFileFormats -SkipTables:$SkipTables -SkipViews:$SkipViews -SkipProcedures:$SkipProcedures -SkipSequences:$SkipSequences -SkipStages:$SkipStages -SkipFileFormats:$SkipFileFormats -SkipFutures:$SkipFutures @ConnectionHash -SFRGBMFile $SFRGBMFile -Verbose:$VerbosePreference -Debug:$DebugPreference

    $FileAccountObjectPermissions = $FileAccountObjectPermissions | Sort-Object -Unique
    $FileSchemaPermissions = $FileSchemaPermissions | Sort-Object -Property @{Expression={$_.Command}; Ascending = $True} -Unique
    $FileSchemaObjectPermissions = $FileSchemaObjectPermissions | Sort-Object -Property @{Expression={$_.Command}; Ascending = $True} -Unique
    
    #Write-Host $SFAccountObjectPermissions
    #Write-Host $FileAccountObjectPermissions

    New-SFPermissionScripts -Databases $AccountDatabases `
        -SFAccountObjectPermissions $SFAccountObjectPermissions `
        -FileAccountObjectPermissions $FileAccountObjectPermissions `
        -FileSchemaPermissions $FileSchemaPermissions `
        -SFSchemaPermissions $SFSchemaPermissions `
        -FileSchemaObjectPermissions $FileSchemaObjectPermissions `
        -SFSchemaObjectPermissions $SFSchemaObjectPermissions `
        -WrapInTransaction:$WrapInTransaction `
        -RunAgainstAccount:$RunAgainstAccount `
        -CreateGoodFile:$CreateGoodFile `
        -GoodFile $GoodFile `
        -GrantFile $GrantFile `
        -RevokeFile $RevokeFile `
        -Verbose:$VerbosePreference `
        -Debug:$DebugPreference `
        -DebugFiles:$DebugFiles
    }
}