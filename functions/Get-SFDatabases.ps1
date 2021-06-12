function Get-SFDatabases {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [string[]]$Name = "%",
        [string]$UID,
        [string]$Authenticator = "snowflake",
        [string]$Role,
        [string]$Warehouse,
        [string]$Server
    )
    PROCESS {
        $Databases = @()
        $ObjectsQuery = "SHOW DATABASES LIKE '$Name';"
        $QueryResults = Get-SFQueryResults -Query $ObjectsQuery -UID $UID -Authenticator $Authenticator -Role $Role -Warehouse $Warehouse -Server $Server -Verbose:$VerbosePreference -Debug:$DebugPreference
        ForEach ($Database in $QueryResults) {
            $DBOrigin = $Database.origin
            IF ($DBOrigin -ne "") {$Shared = $true} Else {$Shared = $false}

            $DBRow = New-Object -TypeName PSObject
            Add-Member -InputObject $DBRow -MemberType 'NoteProperty' -Name 'Name' -Value "$($Database.name)"
            Add-Member -InputObject $DBRow -MemberType 'NoteProperty' -Name 'Shared' -Value "$Shared"

            $Databases += $DBRow
        }
        RETURN $Databases
    }
}