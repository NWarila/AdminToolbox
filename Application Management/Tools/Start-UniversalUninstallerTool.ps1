 <#

-= Universal Uninstaller Tool =-
Insanely quick and very functional uninstaller tool.

VERSION     DATE			NAME						DESCRIPTION
___________________________________________________________________________________________________________
5.0         21 Aug 2020		Warila, Nicholas R.			Initial version

Credits:
    (1) Script Template: https://gist.github.com/9to5IT/9620683

Updates Available at:
    (1) Github: 
#>

#Update Me
[String]$Search = 'Firefox'

#Possible Options are: 'Regex','Simple','Exact'
[String]$SearchType = 'Simple'

#Possible options are "x86", "x64" and "both" (Note: This isn't fool proof, but does fairly good job.)
[String]$Arch = 'both'

# If uninstaller is an exe use these silent uninstall flags. If no flags should be added but still attempt exe uninstalls
# using the install string use 'none'
[String]$EXEFlags = 'none'

#If you would like the script to attempt to extract the uninstall string from the registry. This is used for applications that have
#include uninstall flags in the registry uninstall key. You will have to manually add the uninstall flags to "$EXEFlags" above.
#Possible Options: $True, $False
[Bool]$URLExtraction = $True

# Don't Edit Below this line
###############################################################################################################################
[Bool]$Debug = $False

#Variable Validation; Ensure all required variables are configured.
If ([String]::IsNullOrEmpty($Search)) { Write-Output "[Error] 'Search' variable is empty."; Exit 1 }
If ([String]::IsNullOrEmpty($SearchType) -OR @("Regex","Simple","Exact") -notcontains $SearchType) { Write-Output "[Error] 'SearchType' variable is missconfigured."; Exit 1 }
If ([String]::IsNullOrEmpty($Arch) -OR @("x86","x64","both") -notcontains $Arch) { Write-Output "[Error] 'Arch' variable is missconfigured."; Exit 1 }
If ([String]::IsNullOrEmpty($EXEFlags)) { Write-Output "[Error] 'EXEFlags' variable is empty."; Exit 1 }
If ([String]::IsNullOrEmpty($URLExtraction)) { Write-Output "[Error] 'URLExtraction' variable is not configured.."; Exit 1 }

New-Variable -Name Script -ErrorAction Stop -Force -Value @{
    Applications = New-Object -TypeName 'System.Collections.ArrayList'
    Keys         = New-Object -TypeName 'System.Collections.ArrayList'
    UserKeys     = [Array](Get-ChildItem -Path Registry::HKEY_USERS)
    Properties   = @('DisplayName', 'DisplayVersion', 'ParentKey', 'UninstallString', 'AppArch', 'InstallLocation', 'InstallSource')
}

[Void]$Script.Keys.Add([PSObject]@{
    'HKLM' = "Software\Microsoft\Windows\CurrentVersion\Uninstall"
})

IF ([System.Environment]::Is64BitOperatingSystem) {
    [Void]$Script.Keys.Add([PSObject]@{
        'HKLM' = "SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
    })
}

FOREACH ($UserKey IN $Script.UserKeys) {
    [Void]$Script.Keys.Add([PSObject]@{
        'HKU' = "$($UserKey.PSChildName)\Software\Microsoft\Windows\CurrentVersion\Uninstall"
    })
    Remove-Variable -Name UserKey
}

FOREACH ($Key IN $Script.Keys) {
    SWITCH ($Key.Keys) {
        'HKLM' {
            $BaseKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, $ENV:ComputerName)
        }
        'HKU'  {
            $BaseKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]::Users, $ENV:ComputerName)
        }
        Default {
            Write-Error -Message "Invalid registry key root."
            EXIT 1
        }
    }
    $RegKey = $BaseKey.OpenSubkey($key.Values[0])
    IF ($RegKey -ne $null) {
        FOREACH ($subName IN $RegKey.getsubkeynames()) {
            FOREACH ($sub IN $RegKey.opensubkey($subName)) {
                [string]$Name = $sub.getvalue("displayname")
                IF ($Name.trim().Length -gt 0) {
                    
                    #If search option selected and $Name doesn't match, move to next item
                    IF (![string]::IsNullOrEmpty($Search) -AND (
                            ($SearchType -eq 'Regex' -AND $Name -NotMatch $Search) -OR
                            ($SearchType -eq 'Simple' -AND $Name -NOTLIKE "*$Search*") -OR
                            ($SearchType -eq 'Exact' -AND $Name -NE $Search))
                    ) {
                        CONTINUE
                    }
                    
                    [Hashtable]$HashProperty = @{
                        RegKey = $RegKey
                    }
                    FOREACH ($CurrentProperty IN $Script.Properties) {
                        SWITCH ($CurrentProperty) {
                            "ParentKey" {
                                $HashProperty.ParentKey = $subName
                            }
                            "AppArch" {
                                $HashProperty.AppArch = [String]::Empty
                            }
                            Default {
                                $HashProperty.$CurrentProperty = $sub.GetValue($CurrentProperty)
                            }
                        }
                        Remove-Variable -Name "CurrentProperty" -ErrorAction SilentlyContinue -Force
                    } #End-ForEach

                    #Make best attempt to determine if application is x32 or x64
                    IF ([System.Environment]::Is64BitOperatingSystem) {
                        [Int]$x32 = 0
                        [Int]$x64 = 0
                        IF ($HashProperty.DisplayName -match "x86" -OR $HashProperty.DisplayName -match "x32" -OR $HashProperty.DisplayName -match "32-bit" -OR $HashProperty.DisplayName -match "32bit") {
                            $x32 += 100
                        }
                        IF ($HashProperty.DisplayName -match "x64" -OR $HashProperty.DisplayName -match "64-bit" -OR $HashProperty.DisplayName -match "64bit")  {
                            $x64 += 100
                        }
                        IF (-NOT [String]::IsNullOrEmpty($HashProperty.InstallSource) -AND ($HashProperty.InstallSource -match "x32" -OR $HashProperty.InstallSource -match "32-bit" -OR $HashProperty.InstallSource -match "32bit" -OR $HashProperty.InstallSource -match "x86")) {
                            $x32 += 25
                        }
                        IF (-NOT [String]::IsNullOrEmpty($HashProperty.InstallSource) -AND ($HashProperty.InstallSource -match "x64" -OR $HashProperty.InstallSource -match "64-bit" -OR $HashProperty.InstallSource -match "64bit"))  {
                            $x64 += 25
                        }
                        IF (-NOT [String]::IsNullOrEmpty($HashProperty.InstallLocation) -AND $HashProperty.InstallLocation -match "Program Files (x86)") {
                            $x32 += 10
                        }
                        IF (-NOT [String]::IsNullOrEmpty($HashProperty.InstallLocation) -AND $HashProperty.InstallLocation -match "Program Files") {
                            $x64 += 10
                        }
                        IF ($HashProperty.RegKey -match "Wow6432Node") {
                            $x32 += 10
                        } Else {
                            $x64 += 10
                        }
                        IF ($x32 -GE $x64) {
                            $HashProperty.AppArch = "x86"
                        } Else {
                            $HashProperty.AppArch = "x64"
                        }
                    } Else {
                        $HashProperty.AppArch = "x86"
                    }
                    [Void]$Script.Applications.add([psCustomObject]$HashProperty)
                    Remove-Variable -Name @("HashProperty","x32","x64") -ErrorAction SilentlyContinue -Force
                } #End-IF
            } #End-ForEach
            Remove-Variable -Name @("Name","Sub") -ErrorAction SilentlyContinue -Force
        } #End-Foreach
        Remove-Variable -Name @("Subname") -ErrorAction SilentlyContinue -Force
    } #End-IF
    Remove-Variable -Name Key -ErrorAction SilentlyContinue -Force
} #End-ForEach

ForEach ($App in $Script.Applications) {
    $ProcessStartInfo = New-Object System.Diagnostics.ProcessStartInfo
    $ProcessStartInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
    $ProcessStartInfo.LoadUserProfile = $False
    $ProcessStartInfo.CreateNoWindow = $True
    $ProcessStartInfo.UseShellExecute = $False
    $ProcessStartInfo.RedirectStandardOutput = $True
    $ProcessStartInfo.RedirectStandardInput = $True
    $ProcessStartInfo.RedirectStandardError = $True

    Switch -Regex ($App.UninstallString) {
        #Match files installed with msiexec.
        '^.*\b(?i:msiexec\.exe)\b.*$' {
            $MSIRegex = [Regex]::Match($App.UninstallString,'"?(?<FullName>.*(?i:msiexec\.exe))[" ]*(?<Arguments>.*)$')
            $ProcessStartInfo.FileName = "$ENV:Windir\System32\msiexec.exe"
            IF ($MSIRegex.Groups["Arguments"].value -notcontains "/qn") {
                $ProcessStartInfo.Arguments = ($MSIRegex.Groups["Arguments"].value + " /qn").replace("/I","/X")
            } Else {
                $ProcessStartInfo.Arguments = ($MSIRegex.Groups["Arguments"].value).replace("/I","/X")
            }
            Remove-Variable -Name MSIRegex -ErrorAction SilentlyContinue -Force
        }

        #Match EXE files that aren't msiexec.
        '(?i)^(?=.*?\b\.exe\b)(?:(?!msiexec).)*$' {
            $EXERegex = [Regex]::Match($App.UninstallString,'^"?(?<FullName>[a-z,A-Z]:\\.+\.exe)[" ]*(?<Arguments>.*)$')
            $ProcessStartInfo.FileName = $EXERegex.Groups["FullName"].Value
            IF ($EXEFlags -eq 'None') {
                $ProcessStartInfo.Arguments = $EXERegex.Groups["Arguments"].value
            } Else {
                $ProcessStartInfo.Arguments = $EXEFlags
            }
            Remove-Variable -Name EXERegex -ErrorAction SilentlyContinue -Force
        }

        #Match batch files with CMD or Bat file extentions.
        '^(?i:(?=.*?\b\.cmd\b)|(?=.*?\b\.bat\b)).*$' {
            $BatchRegex = [Regex]::Match($App.UninstallString,'"?(?<FullName>.*(?i:(?:bat|cmd)))[" ]*(?<Arguments>.*)$')
            $ProcessStartInfo.FileName = $BatchRegex.Groups["FullName"].Value
            $ProcessStartInfo.Arguments = $BatchRegex.Groups["Arguments"].value
            Remove-Variable -Name BatchRegex -ErrorAction SilentlyContinue -Force
        }
        Default {
            Write-Output "Unable to handle these kinds of installers/uninstallers."
        }
    }

    IF ($Debug) {
        Write-Output "Uninstalling $($App.DisplayName)"
        $ProcessStartInfo.FileName
        $ProcessStartInfo.Arguments
    } ELSE {
        $Process = [System.Diagnostics.Process]::Start($ProcessStartInfo)
        $Process.WaitForExit()
        Write-Output "Exit Code: $($Process.ExitCode)"
        Remove-Variable -Name @("ProcessStartInfo","app") -ErrorAction SilentlyContinue -Force
    }
}

IF (!$Debug) {
    Remove-Variable -Name @("Script","debug","BaseKey","RegKey","Search","SearchType","Arch","EXEFlags","URLExtraction") -ErrorAction SilentlyContinue -Force
}
