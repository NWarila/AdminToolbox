Function Set-RegistryKey {
    Param (
    [parameter(Mandatory=$True)]
    [ValidateNotNullOrEmpty()]
    [String]$Path,

    [parameter(Mandatory=$False)]
    [ValidateSet("String","ExpandString","Binary","DWord","MultiString","Qword")]
    [String]$Type,

    [parameter(Mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [String]$Name,

    [parameter(Mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [String]$Value
    )
    #Test-Path
    If (-Not (Test-Path -Path $Path)) {
        #If the key doesn't exist, create it.
        Try {
            New-Item -Path $Path -ErrorAction Stop -Force -WhatIf
        } Catch {
            Write-Output "[Error] Unable to create registry key."
            break
        }
    }
    Try {
        New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force -ErrorAction Stop -Verbose
    } Catch {
        
    }
    
}
#(Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced").ShowCortanaButton.GetType()

#Minimize Explorer Ribbon (Tablet Mode Off)
# 1 = Always show (expand)
# 2 = Always hide (minimize) (Default)
[Int]$MinimizedStateTabletModeOff = "0"

#Show hidden files, folders, and drives.
# 1 = Show hidden files, folders, and drives
# 2 = Don't show hidden files, folders, and drives.
[Int]$ShowHidden = "1"

#Cortana Button
# 0 = Don't show Cortana Button
# 1 = Show Cortana Button (Default)
[Int]$CortanaButton = "0"

#Dont Pretty Path
#Windows my default attempts to make files and folders appear prettier instead of showing exactly what they look like.
# 0 = Pretty paths
# 1 = Don't pretty paths
[Int]$DontPrettyPath = "1"

#Show "Task view" Button on Taskbar
# 0 = Hide "Task View" button.
# 1 = Show "Task View" button. (Default)
[Int]$ShowTaskViewButton = "0"

#Apps Use Light Theme
# 0 = Use Windows Light Theme (Default)
# 1 = Use Windows Dark Theme
[Int]$AppsUseLightTheme = "1"

#Quick Access: Show Recent Files
# 0 = Don't show recent files.
# 1 = Show recent files. (Default)
[Int]$ShowRecent = "0"

#Quick Access: Show frequent Files
# 0 = Don't show frequent files.
# 1 = Show frequent files. (Default)
[Int]$ShowFrequent = "0"

#Windows Explore Home Page
# 1 = Open to "This PC"
# 2 = Open to "Quick Access" (Default)
[Int]$LaunchTo = "1"

#Start Menu Bing Search
# 0 = Enable Start Menu Bing Search. (Default)
# 1 = Disable Start Menu Bing Search.
[Int]$BingSearchEnabled = "0"

#Cortana Search Bar On Task Bar
# 0 = Completely hide Cortana on task bar.
# 1 = Show Cortana icon on task bar.
# 2 = Show Cortana search box on task bar.
[Int]$SearchboxTaskbarMode = "1"

#Let Apps Use Advertising ID
# 0 = Don't let apps user Aadvertising ID.
# 1 = Let apps use advertising ID. (Default)
[Int]$UseAdInfo = "0"

#Show Sync Provider Notifications (Feature ads within explorer)
# 0 = Hide Ads.
# 1 = Show Ads. (Default)
[Int]$ShowSyncProviderNotifications  = "0"

#Show People button on taskbar
# 0 = Disable people button.
# 1 = Show people button. (Default)
[Int]$PeopleBand = "0"

#Show Windows Ink Workspace button on taskbar.
# 0 = Hide Windows Ink Workspace button. (Default)
# 1 = Show Windows Ink Workspace button.
[Int]$PenWorkspaceButtonDesiredVisibility = "0"

#Show hidden files, folders, and drives.
Set-RegistryKey -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Ribbon" -Type DWord -Value $MinimizedStateTabletModeOff -Name "MinimizedStateTabletModeOff"

#Show hidden files, folders, and drives.
Set-RegistryKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\" -Type DWord -Value $ShowHidden -Name "hidden"

#Show hidden files, folders, and drives.
Set-RegistryKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\" -Type DWord -Value $CortanaButton -Name "ShowCortanaButton"

#Dont Pretty Path
Set-RegistryKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\" -Type DWord -Value $DontPrettyPath -Name "DontPrettyPath"

#Show Task View Button 
Set-RegistryKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\" -Type DWord -Value $ShowTaskViewButton -Name "ShowTaskViewButton"

#Apps Use Light Theme
Set-RegistryKey -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\" -Type DWord -Value $AppsUseLightTheme -Name "AppsUseLightTheme"

#Quick Access: Show Recent Files
Set-RegistryKey -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\" -Type DWord -Value $ShowRecent -Name "ShowRecent"

#Quick Access: Show Frequent Files
Set-RegistryKey -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\" -Type DWord -Value $ShowFrequent -Name "ShowFrequent"

#Windows Explore Home Page
Set-RegistryKey -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\" -Type DWord -Value $LaunchTo -Name "LaunchTo"

#Start Menu Bing Search
Set-RegistryKey -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search\" -Type DWord -Value $BingSearchEnabled -Name "BingSearchEnabled"

#Cortana Search Bar On Task Bar
Set-RegistryKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search\" -Type DWord -Value $SearchboxTaskbarMode -Name "SearchboxTaskbarMode"

#Let Apps Use Advertising ID
Set-RegistryKey -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo\" -Type DWord -Value $UseAdInfo -name "Enabled"

#Show Sync Provider Notifications
Set-RegistryKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\" -Type DWord -Value $ShowSyncProviderNotifications -Name "ShowSyncProviderNotifications"

#Show People button on taskbar
Set-RegistryKey -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" -Type DWord -Value $PeopleBand -Name "PeopleBand"

#Show Windows Ink Workspace button on taskbar.
Set-RegistryKey -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\PenWorkspace" -Type DWord -Value $PenWorkspaceButtonDesiredVisibility -Name "PenWorkspaceButtonDesiredVisibility"
