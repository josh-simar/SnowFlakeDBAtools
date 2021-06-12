function Get-SFDatabaseProcedures {
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
        $Procedures = @()
        $ObjectsQuery = "SHOW PROCEDURES IN ACCOUNT;"
        $QueryResults = Get-SFQueryResults -Query $ObjectsQuery -UID $UID -Authenticator $Authenticator -Role $Role -Warehouse $Warehouse -Server $Server -Verbose:$VerbosePreference -Debug:$DebugPreference
        ForEach ($Procedure in $QueryResults) {
            IF ($Procedure.schema_name -ne "INFORMATION_SCHEMA") {
                $ProcedureRow = New-Object -TypeName PSObject
                $ProcedureWithoutReturns = $($($($Procedure.arguments).Split(')'))[0])
                $ProcedureWithoutReturns = "$ProcedureWithoutReturns)"
                Add-Member -InputObject $ProcedureRow -MemberType 'NoteProperty' -Name 'DB' -Value "$($Procedure.catalog_name)"
                Add-Member -InputObject $ProcedureRow -MemberType 'NoteProperty' -Name 'SchemaName' -Value "$($Procedure.schema_name)"
                Add-Member -InputObject $ProcedureRow -MemberType 'NoteProperty' -Name 'ProgrammingType' -Value "PROCEDURE"
                Add-Member -InputObject $ProcedureRow -MemberType 'NoteProperty' -Name 'ProcedureName' -Value "$ProcedureWithoutReturns"
                $Procedures += $ProcedureRow
            }
        }
        $ObjectsQuery = "SHOW USER FUNCTIONS IN ACCOUNT;"
        $QueryResults = Get-SFQueryResults -Query $ObjectsQuery -UID $UID -Authenticator $Authenticator -Role $Role -Warehouse $Warehouse -Server $Server -Verbose:$VerbosePreference -Debug:$DebugPreference
        ForEach ($UserFunction in $QueryResults) {
            IF ($UserFunction.schema_name -ne "INFORMATION_SCHEMA") {
                $UserFunctionRow = New-Object -TypeName PSObject
                $UserFunctionWithoutReturns = $($($($UserFunction.arguments).Split(')'))[0])
                $UserFunctionWithoutReturns = "$UserFunctionWithoutReturns)"
                Add-Member -InputObject $UserFunctionRow -MemberType 'NoteProperty' -Name 'DB' -Value "$($UserFunction.catalog_name)"
                Add-Member -InputObject $UserFunctionRow -MemberType 'NoteProperty' -Name 'SchemaName' -Value "$($UserFunction.schema_name)"
                Add-Member -InputObject $UserFunctionRow -MemberType 'NoteProperty' -Name 'ProgrammingType' -Value "FUNCTION"
                Add-Member -InputObject $UserFunctionRow -MemberType 'NoteProperty' -Name 'ProcedureName' -Value "$UserFunctionWithoutReturns"
                $Procedures += $UserFunctionRow
            }
        }


        RETURN $Procedures
    }
}