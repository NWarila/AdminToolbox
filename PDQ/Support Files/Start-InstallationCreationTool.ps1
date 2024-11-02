#Installation directory in which the installer is located.
$InstallerDir = "$(Repository)\Apache\Ant\1.10.8\"

#Icon you want displayed in Add/Remove application menu. (optional)
$InstallIcon = "$(Repository)\Apache\Ant\apache-ant-icon.ico"

#Application Name displayed in Add/Remove application menu.
$AppName = 'Apache Ant'

#Application publisher displayed in Add/Remove application menu.
$AppPublisher = "Apache Software Foundation"

#Specify custom directory name in programs directory.
$CustomDirName = ""

<###############################################################################################################################
# Don't Edit Below this line
###############################################################################################################################
-= Installation Entry Creation Tool =-
Quick and Easy tool to make portable or non-installing applications act like a normal installable application. (Ex. Add/Remove
Programs entry)

VERSION     DATE			NAME						DESCRIPTION
___________________________________________________________________________________________________________
3.1         21 Aug 2020		Warila, Nicholas R.			Initial version

Credits:
    (1) Script Template: https://gist.github.com/9to5IT/9620683

Updates Available at:
    (1) Github: 
#>

New-Variable -Name Script -Description "Main script variable used to store all script used variables" -Force  -Value @{
    Reg = @{
        UninstallPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"
    }
    InstallType = "Copy"
    InstallerDirInv = $Null
    App = @{
        Name = $AppName
        RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\" + $AppName
        InstallerPath = $InstallerDir
        Publisher = $AppPublisher
    }
}

#Check installer Directory
IF ([System.IO.Directory]::Exists($InstallerDir)) {
    $Script.InstallerDirInv = Get-Childitem -Path $InstallerDir
    IF ($Script.InstallerDirInv.count -eq 1 -AND $Script.InstallerDirInv.Extension -eq ".zip") {
        $Script.InstallType = "UNZIP"
    }
} Else {
    Write-Error -Message "Unable to located installation directory." -ErrorAction Stop
}

#Set application installation directory.
If ($CustomDirName -Notmatch "^[a-zA-Z0-9\s]+$") {
    Write-Output "CustomDirName is either empty or contains invalid characters. Reverting to default: $Env:ProgramFiles\$AppName\"
    $Script.App.InstallDir = "$Env:ProgramFiles\$AppName\"
} Else {
    $Script.App.InstallDir = $CustomDirName
}

#Ensure application installation directory is formatted properly.
If ($Script.App.InstallDir[($Script.App.InstallDir.Length-1)] -ne "\") {
    $Script.App.InstallDir = $Script.App.InstallDir + "\"
}
$Script.App.RegInstallDir = $Script.App.InstallDir.Replace("\","\\")

#Set uninstall string
$Script.App.UninstallString = $Script.App.InstallDir + "Uninstall.bat"

#Ensure we have some sort of valid ico file set, even if we have to make one up.
If (-NOT [System.IO.File]::Exists($InstallIcon) -OR (Get-Item $InstallIcon -ErrorAction SilentlyContinue).PSIsContainer) {
    Write-Warning "Unable to locate icon file; skipping icon."
    [Bool]$Script.App.CopyIcon = $False
} Else {
    [Bool]$Script.App.CopyIcon = $True
    $Script.App.InstallIcon = $InstallIcon
}
$Script.App.Icon = $Script.App.InstallDir + "icon.ico"

$Script.App.UninstallScript = @"
@ECHO OFF
CD %SystemDrive%
REG DELETE "$($Script.App.RegPath.replace("HKLM:","HKLM"))" /f
RMDIR "$($Script.App.InstallDir)" /S /Q
ECHO/ Script Complete
pause
exit
"@

If (Test-Path -LiteralPath $Script.App.InstallerPath) {
    Write-Output "Checking for previous installation."
    If ((Get-ChildItem -LiteralPath $Script.app.InstallDir -Recurse -File -ErrorAction SilentlyContinue).count -GT 0 -OR (Test-Path -LiteralPath $Script.App.RegPath)) {
        Try {
            Write-Output "Previous Installation Detected. Attempting to uninstall."
                Remove-item -LiteralPath $Script.App.InstallDir -Recurse -Force -ErrorAction Stop
                Remove-Item -LiteralPath $Script.App.RegPath-Force -ErrorAction Stop
        } Catch {
            Write-Error $_.Exception
            Exit 1
        }
    }

    Write-Output "Starting Installation."
    Try {
        Write-Output "Copying installation files to destination computer."
            IF ($Script.InstallType -eq "Copy") {
                Copy-Item -Path $Script.App.InstallerPath -Destination $Script.App.InstallDir -Include *.* -Container -Recurse -Force -ErrorAction Stop
            } ElseIF ($Script.InstallType -eq "Unzip") {
                Expand-Archive -Path $Script.InstallerDirInv.FullName -DestinationPath $Script.App.InstallDir -Force
            }
            If ($Script.App.CopyIcon) {
                Copy-Item -Path $Script.App.InstallIcon -Destination $Script.App.Icon -Container -Force -ErrorAction Continue
            }
        Write-Output "Getting required information for installation."
            $Script.App.Version = Split-Path -Path $Script.App.InstallerPath -Leaf
            $Script.App.InstallSize = [math]::Round(((Get-ChildItem -Path $Script.App.InstallDir -Recurse | Measure-Object -Property Length -Sum -ErrorAction Stop).Sum / 1KB))
        Write-Output "Creating Program & Features Entry"
            $Null = New-Item -Path $Script.Reg.UninstallPath -Name $Script.App.Name -Force -ErrorAction Stop
            $Null = New-ItemProperty -Path $Script.App.RegPath -Name 'DisplayName' -Value "$AppName (v$($Script.App.Version))" -PropertyType "String" -Force -ErrorAction Stop
            $Null = New-ItemProperty -Path $Script.App.RegPath -Name 'DisplayVersion' -Value $Script.App.Version -PropertyType "String" -Force -ErrorAction Stop
            IF ($Script.App.CopyIcon) {
                $Null = New-ItemProperty -Path $Script.App.RegPath -Name 'DisplayIcon' -Value $Script.App.Icon -PropertyType "String" -Force -ErrorAction Stop
            }
            $Null = New-ItemProperty -Path $Script.App.RegPath -Name 'InstallLocation' -Value $Script.App.InstallDir -PropertyType "String" -Force -ErrorAction Stop
            $Null = New-ItemProperty -Path $Script.App.RegPath -Name 'UninstallString' -Value $Script.App.UninstallString -PropertyType "String" -Force -ErrorAction Stop
            $Null = New-ItemProperty -Path $Script.App.RegPath -Name 'NoModify' -Value 1 -PropertyType "dword" -Force -ErrorAction Stop
            $Null = New-ItemProperty -Path $Script.App.RegPath -Name 'NoRepair' -Value 1 -PropertyType "dword" -Force -ErrorAction Stop
            $Null = New-ItemProperty -Path $Script.App.RegPath -Name 'Publisher' -Value $Script.App.Publisher -PropertyType "String" -Force -ErrorAction Stop
            $Null = New-ItemProperty -Path $Script.App.RegPath -Name 'EstimatedSize' -Value $Script.App.InstallSize -PropertyType "dword" -Force -ErrorAction Stop
        Write-Output "Generating Uninstall.bat"
            Out-File -FilePath $Script.App.UninstallString -InputObject $Script.App.UninstallScript -Force -Encoding ascii
        Write-Output "Script Complete"
            Exit 0
    } Catch {
        Write-Error $_.Exception
    }
} Else {
    Write-Error "Unable to locate installer directory."
    Exit 1
}
