function Get-SFRolesFileUsers {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [PSObject]$SFUserRolesFile
    )
    PROCESS {
        $UsersSection = $SFUserRolesFile.Users
        $Users = @()
        ForEach ($User in $UsersSection) {
            $Users += "CREATE USER IF NOT EXISTS ""$($User.User)"";"
        }
        $Users = $Users | Sort-Object -Unique
        RETURN $Users
    }
}
