function Get-SFRolesFileUserRolesAssignments {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [PSObject]$SFUserRolesFile
    )
    PROCESS {

        $UsersSection = $SFUserRolesFile.Users

        $UserGrants = @()

        ForEach ($User in $UsersSection) {
            ForEach ($Role in $($User.Roles)) {
                $UserGrants += "GRANT ROLE $Role TO USER ""$($User.User)"";"
            }
        }

        RETURN $UserGrants
    }
}