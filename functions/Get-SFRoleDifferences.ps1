function Get-SFRoleDifferences {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [ValidateSet("Good","Grant","Revoke")]
        [string]$Difference,
        [PSObject]$SystemUsersInRoles,
        [PSObject]$FileUsersInRoles,
        [PSObject]$SystemRolesInRoles,
        [PSObject]$FileRolesInRoles
    )
    PROCESS {
        
        $accountRevoke = @()
        $accountGrant = @()
        $accountGood = @()

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