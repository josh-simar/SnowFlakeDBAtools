function Get-SFRGBMFileaccountObjectPrivileges {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [PSObject]$Databases,
        [PSObject]$Warehouses,
        [PSObject]$SFRGBMFile
    )
    PROCESS {
        $FileSFaccountObjectPrivileges = @()
        Foreach ($accountObjectPrivilege in $SFRGBMFile.accountObjectPrivileges) {
            Write-Progress -Activity $accountObjectPrivilege.Purpose
            IF ($accountObjectPrivilege.Databases) {
                ForEach ($Database in $Databases) {
                    $accountObjectPrivilege.Databases = $accountObjectPrivilege.Databases -replace '%', "*"
                    IF ($($Database.Name) -like $($accountObjectPrivilege.Databases)) {
                        ForEach ($Role in $accountObjectPrivilege.Roles ) {
                            IF ($Database.Shared -eq "False" -or $($accountObjectPrivilege.Databases) -eq $($Database.Name)) {
                                ForEach ($Privilege in $($accountObjectPrivilege.Privileges)) {
                                    $FileSFaccountObjectPrivileges += "GRANT $Privilege ON DATABASE $($Database.Name) TO ROLE $Role;"
                                }
                            }
                        }
                    }
                }
            }
            IF ($accountObjectPrivilege.Warehouses) {
                Write-Progress -Activity $accountObjectPrivilege.Purpose
                IF ($accountObjectPrivilege.Databases -eq "*" -or $accountObjectPrivilege.Databases -eq "%") {
                    ForEach ($Warehouse in $Warehouses) {
                        ForEach ($Role in $accountObjectPrivilege.Roles ) {
                            $FileSFaccountObjectPrivileges += "GRANT $($accountObjectPrivilege.Privileges) ON WAREHOUSE $Warehouse TO ROLE $Role;"
                        }
                    }
                }
                Else {
                    ForEach ($Role in $accountObjectPrivilege.Roles ) {
                        $FileSFaccountObjectPrivileges += "GRANT $($accountObjectPrivilege.Privileges) ON WAREHOUSE $($accountObjectPrivilege.Warehouses) TO ROLE $Role;"
                    }
                }
            }
        }
        RETURN $FileSFaccountObjectPrivileges
    }
}
