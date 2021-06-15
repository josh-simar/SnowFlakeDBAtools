function Get-SFRolesFileParentRoleChildRolesAssignments {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [PSObject]$SFUserRolesFile
    )
    PROCESS {

        $RoleSection = $SFUserRolesFile.Roles

        $RoleGrants = @()

        ForEach ($Parent in $RoleSection) {
            ForEach ($Child in $($Parent.Roles)) {
                If (!($Child -eq "SECURITYADMIN" -and $($Parent.User) -eq "ACCOUNTADMIN") -xor ($Child -eq "SYSADMIN" -and $($Parent.User) -eq "ACCOUNTADMIN") -xor ($Child -eq "USERADMIN" -and $($Parent.User) -eq "SECURITYADMIN")) {
                    $RoleGrants += "GRANT ROLE $Child TO ROLE $($Parent.User)"
                }
            }
        }

        RETURN $RoleGrants
    }
}