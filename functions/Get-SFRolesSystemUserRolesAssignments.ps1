function Get-SFRolesSystemUserRolesAssignments {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [string]$UID,
        [string]$Authenticator,
        [string]$Role,
        [string]$Warehouse,
        [string]$Server
    )
    PROCESS {
        $Users = Get-SFQueryResults -UID $UID -Authenticator $Authenticator -Role $Role -Warehouse $Warehouse -Server $Server -Query "SHOW USERS;" -Verbose:$VerbosePreference
        $UserGrants = @()
        ForEach ($User in $Users) {
            $Query = "SHOW GRANTS TO USER ""$($User.name)"";"
            $UserRights = Get-SFQueryResults -UID $UID -Authenticator $Authenticator -Role $Role -Warehouse $Warehouse -Server $Server -Query $Query
            ForEach ($UserRole in $UserRights) {
                    $UserGrants += "GRANT ROLE $($UserRole.role) TO USER ""$($UserRole.grantee_name)"";"
            }
        }
        RETURN $UserGrants
    }
}