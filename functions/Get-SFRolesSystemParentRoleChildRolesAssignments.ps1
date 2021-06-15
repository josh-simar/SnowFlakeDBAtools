function Get-SFRolesSystemParentRoleChildRolesAssignments {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
    )
    PROCESS {

        $Roles = Get-SFQueryResults @ConnectionHash -Query "SHOW ROLES;" -Verbose:$VerbosePreference

        $RoleGrants = @()
        ForEach ($Role in $Roles) {
            $Parent = Get-SFQueryResults @ConnectionHash -Query "SHOW GRANTS OF ROLE $($Role.name);"
            $Parent = $Parent | Where-Object {$_.granted_to -eq "ROLE"}

            ForEach ($Child in $($Parent)) {
                If (!($Child.role -eq "SECURITYADMIN" -and $Child.grantee_name -eq "ACCOUNTADMIN") -xor ($Child.role -eq "SYSADMIN" -and $Child.grantee_name -eq "ACCOUNTADMIN") -xor ($Child.role -eq "USERADMIN" -and $Child.grantee_name -eq "SECURITYADMIN")) {
                    $RoleGrants += "GRANT ROLE $($Child.role) TO ROLE $($Child.grantee_name)"
                }
            }
        }
        RETURN $RoleGrants
    }
}