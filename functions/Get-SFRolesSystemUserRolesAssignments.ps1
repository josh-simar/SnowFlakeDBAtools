function Get-SFRolesSystemUserRolesAssignments {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
    )
    PROCESS {

        $Users = Get-SFQueryResults @ConnectionHash -Query "SHOW USERS;" -Verbose:$VerbosePreference

        $UserGrants = @()
        ForEach ($User in $Users) {
            $UserRights = Get-SFQueryResults @ConnectionHash -Query "SHOW GRANTS TO USER $($User.name);"

            ForEach ($Role in $UserRights) {
                #If (!($Child.name -eq "SECURITYADMIN" -and $Child.grantee_name -eq "ACCOUNTADMIN") -xor ($Child.name -eq "SYSADMIN" -and $Child.grantee_name -eq "ACCOUNTADMIN") -xor ($Child.name -eq "USERADMIN" -and $Child.grantee_name -eq "SECURITYADMIN")) {
                    $UserGrants += "GRANT ROLE $($Role.role) TO USER $($Role.grantee_name);"
                    #GRANT ROLE ETL_DEVELOPER TO USER BHAVANI_SANKAR;
                #}
            }
        }

        RETURN $UserGrants
    }
}