<#
    .SYNOPSIS
        Mount and Configure Default User Profile For All New User Profiles.

    .DESCRIPTION
        This script is used to mount the Default User Profile during the MDT process and configure various options that will adjust the standard user experience in a positive manner.

    .PARAMETER <Parameter_Name>
        

    .INPUTS
        None

    .OUTPUTS
        None

    .NOTES
        Version:        1.0
        Author:         Warilia, Nicholas R.
        Creation Date:  1-13-2020
        Purpose/Change: Initial script development
        Credits:
            (1) Script Template: https://gist.github.com/9to5IT/9620683
#>

Param (

)

#----------------------------------------------------------[Prerequisites]---------------------------------------------------------
#Ensure Script is Running as Administrator (1)
$IsAdmin=[Security.Principal.WindowsIdentity]::GetCurrent()
If ((New-Object Security.Principal.WindowsPrincipal $IsAdmin).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator) -eq $FALSE) {
    Write-Error -Message "You are NOT a local administrator.  Run this script after logging on with a local administrator account."
    Exit 1
}

#---------------------------------------------------------[Initialisations]--------------------------------------------------------
$InformationPreference = 'Continue'

#----------------------------------------------------------[Declarations]----------------------------------------------------------
New-Variable -Name Script -ErrorAction Stop -Force -Value @{
    Dismount = [Int]0
    Loaded = [Bool]
    DismountAttempts = [Int]5
    Keys = @(
        [PSCustomObject]@{'Action'="Update";'Name'="Enabled";'Type'="DWORD";'Value'="0";'Path'="Registry::HKEY_USERS\DEFAULT\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"}                                                   #Removing Advertising ID
        [PSCustomObject]@{'Action'="Update";'Name'="SystemSettingsDownloadMode";'Type'="DWORD";'Value'="3";'Path'="Registry::HKEY_USERS\DEFAULT\Software\Microsoft\Windows\CurrentVersion\DeliveryOptimization"}                           #Disable Delivery Optimization
        [PSCustomObject]@{'Action'="Update";'Name'="EnableAutoTray";'Type'="DWORD";'Value'="0";'Path'="Registry::HKEY_USERS\DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer"}                                                   #Show system tray icons
        [PSCustomObject]@{'Action'="Update";'Name'="HideFileExt";'Type'="DWORD";'Value'="0";'Path'="Registry::HKEY_USERS\DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"}                                             #Show system tray icons
        [PSCustomObject]@{'Action'="Update";'Name'="LaunchTo";'Type'="DWORD";'Value'="1";'Path'="Registry::HKEY_USERS\DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"}                                                #Change default explorer view to my computer
        [PSCustomObject]@{'Action'="Update";'Name'="SearchboxTaskbarMode";'Type'="DWORD";'Value'="0";'Path'="Registry::HKEY_USERS\DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"}                                               #Hide Cortana Search Bar
        [PSCustomObject]@{'Action'="Update";'Name'="Enabled";'Type'="DWORD";'Value'="0";'Path'="Registry::HKEY_USERS\DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.SecurityAndMaintenance"} #Disable Security and Maintenance Notifications
        [PSCustomObject]@{'Action'="Update";'Name'="MinimizedStateTabletModeOff";'Type'="DWORD";'Value'="0";'Path'="Registry::HKEY_USERS\DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Ribbon"}                               #Show ribbon in File Explorer
        [PSCustomObject]@{'Action'="Update";'Name'="ShowTaskViewButton";'Type'="DWORD";'Value'="0";'Path'="Registry::HKEY_USERS\DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"}                                      #Hide Taskview button on Taskbar
        [PSCustomObject]@{'Action'="Delete";'Name'="OneDriveSetup";'Type'="";'Value'="";'Path'="Registry::HKEY_USERS\DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"}                                                               #Remove OneDrive Setup from the RUN key
        [PSCustomObject]@{'Action'="Update";'Name'="PeopleBand";'Type'="DWORD";'Value'="0";'Path'="Registry::HKEY_USERS\DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People"}                                       #Hide People button from Taskbar
        [PSCustomObject]@{'Action'="Update";'Name'="DisableFileSyncNGSC";'Type'="DWORD";'Value'="1";'Path'="Registry::HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\OneDrive"}                                                    #Disable One Drive
        [PSCustomObject]@{'Action'="Delete";'Name'="WindowsWelcomeCenter";'Type'="";'Value'="";'Path'="Registry::HKEY_USERS\DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"}                                                        #Disable Windows Welcome Center

    )
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------
#Mount the Default User Registry
Try {
    REG LOAD "HKU\Default" "$($ENV:SystemDrive)\Users\Default\ntuser.dat" |Out-Null
    Write-Information "Mounted '$($ENV:SystemDrive)\Users\Default\ntuser.dat' at 'HKU\Default'"
} Catch {
    Write-Error -ErrorId $LASTEXITCODE -Exception $Error[0].Exception
}


#Script running too quickly and not giving time for registry to fully mount
New-Variable -Name "I" -Value 0 -Force -ErrorAction Stop
While ($I -lt 30 -AND $Script.Loaded -ne $True) {
    IF (!(Test-Path "Registry::HKEY_USERS\DEFAULT\")) {
        Write-Information "Starting Sleep"
        Start-Sleep -s 1
        $I++
    } Else {
        Remove-Variable -Name I -Force
        Write-Information "Successfully loaded Registry"
        $Script.Loaded = $True
    }
}

#Process Configured Keys
ForEach ($Key in $Script.Keys) {
    IF($Key.Action -eq "Update") {
        If (!(Test-Path $Key.Path)) {
            Try {
	            New-Item -Path $Key.Path -Name $Key.Name -Force | Out-Null
                Write-Information "Creating New Registry Key: '$($Key.Path)$($Key.Name)'"
            } Catch {
            Write-Error $Error[0]
            }
        }
        Try {
            Set-ItemProperty -Path $Key.Path -Name $Key.Name -Type $Key.Type -Value $Key.Value
            Write-Information -MessageData "Setting '$($Key.Path)$($Key.Name)' to '$($Key.Value)'"
        } Catch {
            Write-Error -ErrorId $LASTEXITCODE -Exception $Error[0]
        }
    } ElseIF ($Key.Action -EQ "Delete") {
        If (!(Test-Path $Key.Path)) {
            Remove-ItemProperty -Path $Key.Path -Name $Key.Name | Out-Null
        }
    } Else {
        Write-Warning "Invalid Registry Action: $($Key.action)"
    }
}

#Start Garbage Collection
[gc]::Collect()

#Unload the Registry
New-Variable -Name "I" -Value 0 -Force -ErrorAction Stop
while ($Script.Loaded -EQ $True -and ($Script.Dismount -le $Script.DismountAttempts)) {
    Try {
        REG UNLOAD "HKU\Default" |Out-Null
        $Script.Loaded = $False
        Write-Information -MessageData "Successfully unmounted Default Users registry hive."
    } Catch {
        $I += 1
        Write-Information -MessageData "Unable to unmount default user registry hive. (Attempt $I/$($Scipt.DismountAttempts))"
    }
}

#Warn if registry hive wasn't able to be dismounted.
IF ($Script.Loaded) {
    Write-Warning -Message "Unable to dismount Default Users registry hive."
}

#Finishing Up
if ($Script.Loaded -eq $True) {
  Write-Error "Unable to dismount default user registry hive at HKLM\DEFAULT - manual dismount required"
}

#Cleanup Script Variables
Remove-Variable -Name Script -Include * -Scope 0