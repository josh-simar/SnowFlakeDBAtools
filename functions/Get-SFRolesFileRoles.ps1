function Get-SFRolesFileRoles {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [PSObject]$SFUserRolesFile
    )
    PROCESS {
        $UsersSection = $SFUserRolesFile.Users
        $Roles = @()
        ForEach ($User in $UsersSection) {
            ForEach ($Role in $($User.Roles)) {
                $Roles += "CREATE ROLE IF NOT EXISTS $Role;"
            }
        }
        $RolesSection = $SFUserRolesFile.Roles
        ForEach ($ParentRole in $RolesSection) {
            $Roles += "CREATE ROLE IF NOT EXISTS $($ParentRole.User);"
            ForEach ($Role in $($ParentRole.Roles)) {
                $Roles += "CREATE ROLE IF NOT EXISTS $Role;"
            }
        }
        $Roles = $Roles | Sort-Object -Unique
        RETURN $Roles
    }
}