Function Update-User {
    PARAM(
        [String]$Username,
        $RemoveFlags,
        $AddFlags,
        [String]$Description,
        [String]$Name,
        [String]$LocalAdmin,
        [String]$FullName,
        [String]$SetPassword,
        [Switch]$SetRandomPassword,
        [Switch]$CreateIfNot
    )
 
    <#
        $SCRIPT=1
        $ACCOUNTDISABLE=2
        $HOMEDIR_REQUIRED=8
        $LOCKOUT=16
        $PASSWD_NOTREQD=32
        $PASSWD_CANT_CHANGE=64
        $ENCRYPTED_TEXT_PASSWORD_ALLOWED=128
        $TEMP_DUPLICATE_ACCOUNT=256
        $NORMAL_ACCOUNT=512
        $INTERDOMAIN_TRUST_ACCOUNT=2048
        $WORKSTATION_TRUST_ACCOUNT=4096
        $SERVER_TRUST_ACCOUNT=8192
        $DONT_EXPIRE_PASSWD=65536
        $MNS_LOGON_ACCOUNT=131072
        $SMARTCARD_REQUIRED=262144
        $TRUSTED_FOR_DELEGATION=524288
        $NOT_DELEGATED=1048576
        $USE_DES_KEY_ONLY=2097152
        $DONT_REQUIRE_PREAUTH=4194304
        $PASSWORD_EXPIRED=8388608
        $TRUSTED_TO_AUTHENTICATE_FOR_DELEGATION=16777216
    #>

    #Begin
    $ADSI = [ADSI]"WinNT://$Env:ComputerName"
    $LocalUsers = ($ADSI.children |Where-Object {$_.schemaclassname -eq 'user'} |Select name).name

    IF ($LocalUsers -contains $Username) {
        $User = [ADSI]"WinNT://$env:computername/$userName,user"
    } ElseIF ($LocalUsers -NotContains $Username -AND $CreateIfNot) {
        $User = $ADSI.Create("User",$Username)
        IF (!$SetPassword) { $User.SetPassword(([char[]](Get-Random -Input $(33..38 + 48..57 + 65..90 + 97..122) -Count 127)) -join "") }
        $User.SetInfo()
    }

    #Add Flags
    ForEach ($Flag in $AddFlags) {
            $User.invokeSet("userFlags", ($User.userFlags[0] -BOR $flag))
    }
    #Remove Flag Attributes
    ForEach ($Flag in $RemoveFlags) {
            $FlagInt = [int]$Flag
            if ($User.UserFlags[0] -BAND $FlagInt) {
                $User.invokeSet("userFlags", ($User.userFlags[0] -BXOR $FlagInt))
            }
    }

    #Commit flag based changes
    $User.commitChanges()

    #Set NonFlag based options.
    IF ($Description) {$User.Description=$Description}
    IF ($FullName) {$User.FullName=$FullName}
    IF ($Name) {$User.Name=$Name}
    IF ($SetRandomPassword) {$User.SetPassword(([char[]](Get-Random -Input $(33..38 + 48..57 + 65..90 + 97..122) -Count 127)) -join "")}
    #Commit non-flag based changes
    $User.SetInfo()

    IF ($SetPassword) {
        $User.SetPassword($SetPassword)
        $User.SetInfo()
    }
}

Function Update-Group {
    Param(
        [String]$AddUsers,
        [String]$Group
    )
    $TargetGroup = [ADSI]"WinNT://$Env:ComputerName/$Group,group"
    $Members = (($TargetGroup).Invoke("Members") |ForEach { $_.GetType().InvokeMember("Name", 'GetProperty', $Null, $_, $Null) })
    $LocalUsers = (([ADSI]"WinNT://$Env:ComputerName").children |Where-Object {$_.schemaclassname -eq 'user'} |Select name).name
    ForEach ($User in $AddUsers) {
        IF ($LocalUsers -Contains $User) {
            IF ($Members -NotContains $User) {
                $TargetGroup.Add("WinNT://$Env:ComputerName/$User,user")
            } Else {
                Write-Host "$User is already a part of $Group."
            }
        } Else {
            Write-Host "Unable to add to group; $User doesn't exist."
        }
    }
}

IF((Get-WmiObject -Class Win32_OperatingSystem).ProductType -eq "2") {
    Write-host "Detected this system is a DC; Stopping script;"
    Break
}

$Script = @{
    LocalAdmin = $LocalAdmin
    BuildInLocalUsers = (Get-WmiObject Win32_UserAccount -Filter "LocalAccount='True'" | where { $_.SID -match '^S-1-5-21.*-50[0,1]$'}| select name)
}

#Standardize local user accounts
Update-User -Username $Script.LocalAdmin -RemoveFlags "2","8","16","32","64","65536","262144","8388608" -CreateIfNot

#Ensure local admin account is apart of the Administrators Group
Update-Group -AddUsers $Script.LocalAdmin -Group Administrators

#Configure Buildin Local Administrator and Guest accounts.
ForEach ($User in $Script.BuildInLocalUsers) {
    Update-User -Username $User.name -RemoveFlags "8","16","32","64","65536","262144","8388608" -AddFlags "2" -SetRandomPassword
}
