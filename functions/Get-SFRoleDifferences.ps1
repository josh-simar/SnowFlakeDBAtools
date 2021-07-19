function Get-SFRoleDifferences {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [ValidateSet("Good","Grant","Revoke")]
        [string]$Difference,
        [PSObject]$SystemUsersInRoles,
        [PSObject]$FileUsersInRoles,
        [PSObject]$SystemRolesInRoles,
        [PSObject]$FileRolesInRoles,
        [PSObject]$SystemRoles,
        [PSObject]$FileRoles,
        [PSObject]$SystemUsers,
        [PSObject]$FileUsers
    )
    PROCESS {
        
        $accountRevoke = @()
        $accountGrant = @()
        $accountGood = @()

        $accountRevoke += "//Roles to Create"
        $accountGrant += "//Roles to Create"
        $accountGood += "//Roles to Create"

        $Roles = Compare-Object -ReferenceObject $FileRoles -DifferenceObject $SystemRoles -IncludeEqual
        ForEach ($Line in $Roles) {
            IF ($Line.SideIndicator -eq "=>") { $accountRevoke += $($Line.InputObject) -replace 'CREATE ', 'DROP ' -replace ' IF NOT EXISTS ', ' ' }
            IF ($Line.SideIndicator -eq "<=") { $accountGrant += "$($Line.InputObject)" }
            IF ($Line.SideIndicator -eq "==") { $accountGood += "$($Line.InputObject)" }
        }

        $accountRevoke += "//Users to Create"
        $accountGrant += "//Users to Create"
        $accountGood += "//Users to Create"

        $Roles = Compare-Object -ReferenceObject $FileUsers -DifferenceObject $SystemUsers -IncludeEqual
        ForEach ($Line in $Roles) {
            $Password = [System.Web.Security.Membership]::GeneratePassword(12, 2)
            IF ($Line.SideIndicator -eq "=>") { $accountRevoke += $($Line.InputObject) -replace 'CREATE ', 'DROP ' -replace ' IF NOT EXISTS ', ' ' }
            IF ($Line.SideIndicator -eq "<=") { $accountGrant += "$($Line.InputObject) PASSWORD = '$Password'" }
            IF ($Line.SideIndicator -eq "==") { $accountGood += "$($Line.InputObject)" }
        }

        $accountRevoke += "//Role based Roles"
        $accountGrant += "//Role based Roles"
        $accountGood += "//Role based Roles"

        $RolesInRoles = Compare-Object -ReferenceObject $FileRolesInRoles -DifferenceObject $SystemRolesInRoles -IncludeEqual
        ForEach ($Line in $RolesInRoles) {
            IF ($Line.SideIndicator -eq "=>") { $accountRevoke += $($Line.InputObject) -replace 'GRANT ', 'REVOKE ' -replace ' TO ', ' FROM ' }
            IF ($Line.SideIndicator -eq "<=") { $accountGrant += "$($Line.InputObject)" }
            IF ($Line.SideIndicator -eq "==") { $accountGood += "$($Line.InputObject)" }
        }

        $accountRevoke += "//Role based Users"
        $accountGrant += "//Role based Users"
        $accountGood += "//Role based Users"

        $UsersInRoles = Compare-Object -ReferenceObject $FileUsersInRoles -DifferenceObject $SystemUsersInRoles -IncludeEqual
        ForEach ($Line in $UsersInRoles) {
            IF ($Line.SideIndicator -eq "=>") { $accountRevoke += $($Line.InputObject) -replace 'GRANT ', 'REVOKE ' -replace ' TO ', ' FROM ' }
            IF ($Line.SideIndicator -eq "<=") { $accountGrant += "$($Line.InputObject)" }
            IF ($Line.SideIndicator -eq "==") { $accountGood += "$($Line.InputObject)" }
        }

        If ($Difference -eq "Revoke") { RETURN $accountRevoke }
        If ($Difference -eq "Grant") { RETURN $accountGrant }
        If ($Difference -eq "Good") { RETURN $accountGood }
    }
}