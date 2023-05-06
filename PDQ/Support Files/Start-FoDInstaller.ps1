#Update Me
[String]$Search = '.*(?i:RSAT|Print\.Management\.Console).*'

#Possible Options are: 'Regex','Simple','Exact'
[String]$SearchType = 'Regex'

#Use Microsoft Update Servers
#If WSUS servers are configured this option will most likely not work.
$UseMS = $False

#There should be a repository entry for each OS build.
[Hashtable]$Repositories = @{
    1903 = '\\ucva-pdq01.ttc.com\pdq$\microsoft\Features-On-Demand\1903-1909'
    1909 = '\\ucva-pdq01.ttc.com\pdq$\microsoft\Features-On-Demand\1903-1909'
    2004 = '\\ucva-pdq01.ttc.com\pdq$\microsoft\Features-On-Demand\2004'
}

<# Don't Edit Below this line
###############################################################################################################################
-= Features On Demand Tool =-
Quick and easy way to install Windows capabilities (features)

VERSION     DATE			NAME						DESCRIPTION
___________________________________________________________________________________________________________
5.0         21 Aug 2020		Warila, Nicholas R.			Initial version
Credits:
    (1) Script Template: https://gist.github.com/9to5IT/9620683

Updates Available at:
    (1) Github: 
#>


If ([String]::IsNullOrEmpty($Search)) { Write-Output "[Error] 'Search' variable is empty."; Exit 1 }
If ([String]::IsNullOrEmpty($SearchType) -OR @("Regex","Simple","Exact") -notcontains $SearchType) { Write-Output "[Error] 'SearchType' variable is missconfigured."; Exit 1 }
If ([String]::IsNullOrEmpty($UseMS)) { Write-Output "[Error] 'URLExtraction' variable is not configured."; Exit 1 }
IF ($UseMS -eq $False) {
    If ([String]::IsNullOrEmpty($Repositories)) { Write-Output "[Error] 'Repositories' variable is empty."; Exit 1 }
}

New-Variable -Name Script -ErrorAction Stop -Force -value @{
    WindowsCapabilities = Get-WindowsCapability -Online
    AlreadyInstalled    = [Int]0
    ErrorCount          = [Int]0
    ReleaseID           = [Int](Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name ReleaseID).ReleaseID
}

#If using MS servers, then you do not need validate local repository.
IF ($UseMS -eq $False) {
    IF (-NOT [String]::IsNullOrEmpty($Repositories[$Script.ReleaseID])) {
        IF (-NOT (Test-Path -Path $Repositories[$Script.ReleaseID] -PathType Container)) {
            Write-Output -InputObject "[Error] Unable to verify repository exists. (Repository: $($Repositories[$Script.ReleaseID]))"
            Exit 1
        }
    } Else {
        Write-Output -InputObject "[Error] No repository is configured for computer build. (Build: $($Script.ReleaseID))"
        Exit 2
    }
}

ForEach ($FOD in $Script.WindowsCapabilities) {
    IF (![string]::IsNullOrEmpty($Search) -AND (
            ($SearchType -eq 'Regex' -AND $($FOD.name) -NotMatch $Search) -OR
            ($SearchType -eq 'Simple' -AND $($FOD.name) -NOTLIKE "*$Search*") -OR
            ($SearchType -eq 'Exact' -AND $($FOD.name) -NE $Search))
    ) {
        #Write-Output -InputObject "[Debug] $($FOD.name) does not match search."
    } Else {
        IF ($FOD.State -eq "Installed") {
            Write-Output "Package '$($FOD.name)' already installed."
            $Script.AlreadyInstalled++
        } Else {
            Try {
                Write-Output -InputObject "[Debug] Attempting to install $($FOD.name)."
                IF ($UseMS) {
                    [void](Add-WindowsCapability -Online -Name $FOD.name -ErrorAction Stop)
                } Else {
                    [void](Add-WindowsCapability -Online -Name $FOD.name -Source $Repositories[$Script.ReleaseID] -LimitAccess -ErrorAction Stop)
                }
            } Catch {
                Write-Output -InputObject "[Error] Error installing $($FOD.name). (Error: $($Error[0].Exception.Message.trim()))"
                [Int]$Script.ErrorCount++
            }
        }
    }
    Remove-Variable -Name "FOD" -ErrorAction SilentlyContinue -Force
}

IF ($Script.ErrorCount -ne 0) {
    Remove-Variable -Name @("Script","FOD","Repositories","UseMS","SearchType","Search") -ErrorAction SilentlyContinue -Force
    Write-Output "[Error] All Packages that attempted to install were already installed."
    Exit 99
} Else {
    Remove-Variable -Name @("Script","FOD","Repositories","UseMS","SearchType","Search") -ErrorAction SilentlyContinue -Force
    Write-Output "[Success] All requested packages are now installed."
    Exit 0
}
