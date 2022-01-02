#Search text
[String]$Search = "Apache Ant"

#Specify what search method is utilized
#Possible Options are: 'Regex','Simple','Exact
[String]$SearchType = 'Simple'

#What should the name of the variable be.
[String]$VariableName = "ANT_HOME"

<###############################################################################################################################
# Don't Edit Below this line
###############################################################################################################################
-= Installation Entry Creation Tool =-
Dynamic Environmental Variable updater 

VERSION     DATE			NAME						DESCRIPTION
___________________________________________________________________________________________________________
2.0			21 Aug 2020		Warila, Nicholas R.			Initial version
Credits:
    (1) Script Template: https://gist.github.com/9to5IT/9620683

Updates Available at:
    (1) Github: 
#>

If ([String]::IsNullOrEmpty($Search)) { Write-Output "[Error] 'Search' variable is empty."; Exit 1 }
If ([String]::IsNullOrEmpty($SearchType) -OR @("Regex","Simple","Exact") -notcontains $SearchType) { Write-Output "[Error] 'SearchType' variable is missconfigured."; Exit 1 }
If ([String]::IsNullOrEmpty($VariableName)) { Write-Output "[Error] 'VariableName' variable is empty."; Exit 1 }

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

If ($Script.Applications.count -eq 0) {
    Write-Output "[Error] No applications were found."
} ElseIF ($Script.Applications.count -eq 1) {
    Try {
        [Environment]::SetEnvironmentVariable($VariableName,($Script.Applications[0]).InstallLocation,"Machine")
        Exit 0
    } Catch {
        Exit 1
    }
} Else {
    Write-Output "[Error] More than 1 application was found."
}
