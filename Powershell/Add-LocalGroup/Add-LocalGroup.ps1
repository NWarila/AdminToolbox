Function Add-LocalGroup {
    Param(
        [String]$user,
        [String]$Group
    )

    New-Variable -name ADSI -value (([ADSI]"WinNT://$($ENV:ComputerName),computer").psbase.children) -Force -ErrorAction Stop

    #Get Local Accounts
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
    
    #Get target user object.
    New-Variable -Name TargetUser -value ($LocalAccounts.Where({$_.name -eq $user})) -Force
    
    #If the user doesn't exist throw an error.
    If ([String]::IsNullOrEmpty($TargetUser.name) -eq $True) {
        Write-Warning -Message "Error: User doesn't exist."
        break
    }

    #Get list of local accounts.
    New-Variable -Name LocalGroups   -Force -Value (New-Object System.Collections.ArrayList) -ErrorAction Stop
    New-Variable -Name GroupTypes    -Force -Value @{"2" = "Global";"4" = "DomainLocal";"8" = "Universal"}
    New-Variable -Name GroupLocation -Force -Value @{"$env:USERDOMAIN" = "Domain";"NT AUTHORITY" = "Local";"$ENV:COMPUTERNAME" = "Local"}
    $ADSI | Where-Object {$_.schemaClassName -match "group"} |select -Skip 1 | foreach-object {
        New-Variable -Name CurrentGroup -Force -Value ([PSCustomObject]@{
            Name                       = $_.name.value -as [string]
            GroupType                  = $GroupTypes["$($_.GroupType.value)"] -As [String]
            Description                = $_.Description.value -as [string]
            SID                        = (New-Object System.Security.Principal.SecurityIdentifier($_.objectSid.value,0)).Value -as [String]            
            Members                    = New-Object System.Collections.ArrayList
        })
        ([ADSI]$_.psbase.Path).psbase.Invoke("Members") | ForEach-Object {
            [void]$CurrentGroup.Members.Add([PSCustomObject]@{
                Name      = $_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)
                SID       = (New-Object System.Security.Principal.SecurityIdentifier($_.GetType().InvokeMember("ObjectSID", 'GetProperty', $null, $_, $null),0)).value
                ADsPath   = $_.GetType().InvokeMember("ADsPath", 'GetProperty', $null, $_, $null)
                GroupType = $GroupLocation["$($_.GetType().InvokeMember('ADsPath', 'GetProperty', $null, $_, $null).split('/')[2])"]
            })
        }
        [Void]$LocalGroups.Add($CurrentGroup)
    }

    #Get target group object.
    New-Variable -Name TargetGroup -value ($LocalGroups.where({$_.name -eq $Group})) -Force

    #If the group doesn't exist throw an error.
    If ([String]::IsNullOrEmpty($LocalGroups.name) -eq $True) {
        Write-Warning -Message "Error: Group doesn't exist."
        break
    } ElseIF ($TargetGroup.Members.count -gt 0 -and $TargetGroup.Members.sid.Contains($TargetUser.sid) -eq $True) {
        Write-information -MessageData "User already a member of this group."
        break
    } Else {
        ([ADSI]"WinNT://$($ENV:ComputerName)/$($TargetGroup.Name),group").psbase.Invoke("Add",([ADSI]"WinNT://$($ENV:ComputerName)/$($TargetUser.Name),User").path)
    }
    Remove-Variable -name @("$user","$Group","ADSI","LocalAccounts","TargetUser","LocalGroups","GroupTypes","GroupLocation","CurrentGroup","TargetGroup") -Force -ErrorAction SilentlyContinue
}
