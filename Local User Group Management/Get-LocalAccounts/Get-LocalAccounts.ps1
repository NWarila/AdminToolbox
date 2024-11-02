New-Variable -name ADSI -value (([ADSI]"WinNT://$($Env:ComputerName)").psbase.children) -Force -ErrorAction Stop
New-Variable -Name LocalAccounts -Value (New-Object System.Collections.ArrayList) -Force -ErrorAction Stop
$ADSI | Where-Object {$_.schemaClassName -match "user"} | foreach-object {
    [Void]$LocalAccounts.add([PSCustomObject]@{
        Name                       = $_.name.value -as [string]
        FullName                   = $_.fullName.value -as [string]
        Description                = $_.Description.value -as [string]
        PasswordAge                = $_.PasswordAge.value -as [string]
        BadPasswordAttempts        = $_.BadPasswordAttempts.value -as [int]
        HomeDirectory              = $_.HomeDirectory.value -as [System.IO.DirectoryInfo]
        LoginScript                = $_.LoginScript.value -as [System.IO.fileInfo]
        Profile                    = $_.Profile.value -as [System.IO.DirectoryInfo]
        HomeDirDrive               = $_.HomeDirDrive.value -as [System.IO.DirectoryInfo]
        PrimaryGroupID             = $_.PrimaryGroupID.value -as [Int]
        MinPasswordLength          = $_.MinPasswordLength.value -as [Int]
        MaxPasswordAge             = "$((New-TimeSpan -Seconds ([Int]$_.MaxPasswordAge.Value)).days) Days"
        MinPasswordAge             = "$((New-TimeSpan -Seconds ([Int]$_.MinPasswordAge.Value)).days) Days"
        PasswordHistoryLength      = $_.PasswordHistoryLength.value -as [Int]
        AutoUnlockInterval         = "$((New-TimeSpan -Seconds ([Int]$_.AutoUnlockInterval.Value)).days) Minutes"
        LockoutObservationInterval = "$((New-TimeSpan -Seconds ([Int]$_.LockoutObservationInterval.Value)).days) Minutes"
        MaxBadPasswordsAllowed     = $_.MaxBadPasswordsAllowed.value -as [Int]
        SID                        = (New-Object System.Security.Principal.SecurityIdentifier($_.objectSid.value,0)).Value -as [String]
    })
}
