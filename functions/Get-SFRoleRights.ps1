function Get-SFRoleRights {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [PSObject]$Roles,
        [string]$UID,
        [string]$Authenticator = "snowflake",
        [string]$Role,
        [string]$Warehouse,
        [string]$Server
    )
    $RoleRights = @()
    $Over10000 = $false
    ForEach ($Role in $Roles) {
        $ObjectsQuery = "SHOW GRANTS TO ROLE $Role;"
        $QueryResults = Get-SFQueryResults -Query $ObjectsQuery -UID $UID -Authenticator $Authenticator -Role $Role -Warehouse $Warehouse -Server $Server -Verbose:$VerbosePreference -Debug:$DebugPreference
        #$QueryResults | Format-Table
        [PSObject]$RoleRight = @()
        IF ($QueryResults.Count -ge 10000) {
            Write-Error "Over 10000 grants so not all are showing"
            $RoleRights = ""
            $Over10000 = $true}
        Else {
            IF (!($Over10000)) {
                $QueryResults = $QueryResults | Where-Object { $_.privilege -notin "OWNERSHIP", "REFERENCE_USAGE"}
                ForEach ($RoleRight in $QueryResults) {
                    $Level = "schemaObject"
                    $Database = ""
                    IF ($($RoleRight.granted_on) -eq "FILE_FORMAT") { $RoleRight.granted_on = "FILE FORMAT" }
                    IF ($($RoleRight.granted_on) -in 'ROLE') {$Level = "global" }
                    IF ($($RoleRight.granted_on) -in 'USER','RESOURCE MONITOR','WAREHOUSE','DATABASE','INTEGRATION') {$Level = "accountObject" }
                    IF ($($RoleRight.granted_on) -in 'SCHEMA') {$Level = "schema" }
                    IF ($Level -ne "accountObject") { $Database = ($($RoleRight.name) -split "\.")[0] }
                    IF ($Level -eq "accountObject" -and $($RoleRight.granted_on) -eq "DATABASE") { $Database = $($RoleRight.name) }

                    $ObjectName = $($RoleRight.name)

                    IF ($ObjectName -like "*)*") {
                        $ObjectNameScrubbedFirstSection = $($($($ObjectName).Split('('))[0])
                        $ObjectNameScrubbedSecondSection =  $($($($ObjectName).Split('('))[1])
                        $ObjectNameScrubbedSecondSection =  $($($($ObjectNameScrubbedSecondSection).Split(')'))[0])
                        $ObjectNameScrubbedSecondSectionArray =  $($($($ObjectNameScrubbedSecondSection).Split(' ')))
                        $ObjectNameScrubbedSecondSectionArray =  $($($($ObjectNameScrubbedSecondSectionArray).Split(',')))
                        $ObjectNameScrubbedSecondSectionArray = $ObjectNameScrubbedSecondSectionArray | Where-Object {$_ -in "NUMBER", "FLOAT", "VARCHAR", "BINARY", "BOOLEAN", "DATE", "TIMESTAMP_NTZ", "TIME", "VARIANT", "OBJECT", "ARRAY", "GEOGRAPHY" }
                        IF ($ObjectNameScrubbedSecondSectionArray) { $ObjectNameScrubbedSecondSection = [system.String]::Join(", ", $ObjectNameScrubbedSecondSectionArray) } Else { $ObjectNameScrubbedSecondSection = ""}
                        $ObjectName = "$ObjectNameScrubbedFirstSection($ObjectNameScrubbedSecondSection)" -replace """", ""
                    }

                    IF ($($RoleRight.granted_on) -eq "FILE FORMAT") {
                        $ObjectNameArray = $ObjectName.Split(".")
                        $ObjectNameArray = $ObjectNameArray.Split("""")
                        $ObjectName = "$($ObjectNameArray[0]).$($ObjectNameArray[1]).""$($ObjectNameArray[2])$($ObjectNameArray[3])"""
                    }

                    $RoleRightRow = New-Object -TypeName PSObject
                    Add-Member -InputObject $RoleRightRow -MemberType 'NoteProperty' -Name 'Level' -Value "$Level"
                    Add-Member -InputObject $RoleRightRow -MemberType 'NoteProperty' -Name 'DB' -Value "$Database"
                    Add-Member -InputObject $RoleRightRow -MemberType 'NoteProperty' -Name 'ObjectType' -Value "$($RoleRight.granted_on)"
                    Add-Member -InputObject $RoleRightRow -MemberType 'NoteProperty' -Name 'ObjectName' -Value "$ObjectName"
                    Add-Member -InputObject $RoleRightRow -MemberType 'NoteProperty' -Name 'Command' -Value "GRANT $($RoleRight.privilege) ON $($RoleRight.granted_on) $ObjectName TO ROLE $($RoleRight.grantee_name);"
                    $RoleRights += $RoleRightRow

                    #IF ($($RoleRight.grantee_name) -eq "PUBLIC") { Write-Host $RoleRightRow}
                }
            }
        }
    }
    RETURN $RoleRights
}
#$SystemRoles = Get-SFRoles @ConnectionHash
#$SystemRoles = $SystemRoles | Where-Object {$_ -notin @('ACCOUNTADMIN','SECURITYADMIN','SYSADMIN','USERADMIN')}
#$SystemRoles = $SystemRoles | Where-Object {$_ -eq "PUBLIC"}
#Get-SFRoleRights -Roles $SystemRoles @ConnectionHash -Verbose
#$RoleRights | Where-Object {$_.Level -eq "accountObject" } | Format-Table
#$RoleRights | Where-Object {$_.Level -eq "schema"} | Select-Object DB,Command
#$RoleRights | Where-Object { $_.Level -eq "accountObject" } | Format-Table
#$RoleRights | Where-Object { $_.Command -like "*UTIL_DB*"} | Select-Object DB,Command