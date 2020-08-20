<#
    .SYNOPSIS
        Get a detailed list of previous logons.

    .DESCRIPTION
        Generate a list of logons,logoffs,locks, and unlocks.

    .PARAMETER Computers
        [String[]] String list of computers you want to search through.

    .PARAMETER Days
        [Int] Numbers of days to go back.
        
    .INPUTS
        None

    .OUTPUTS
        None

    .NOTES

    VERSION     DATE			NAME						DESCRIPTION
	___________________________________________________________________________________________________________
	1.0         20 August 2020	Warilia, Nicholas R.		Initial version

    Credits:
        (1) Script Template: https://gist.github.com/9to5IT/9620683
#>

Param (
    [string[]]$Computers = $ENV:COMPUTERNAME,
    [int]$Days = 10
)

New-Variable -Name Script -Force -ErrorAction Stop -Value @{
    StartTime = [DateTime]::Now
    Events    = New-Object System.Collections.ArrayList
}

ForEach ($Computer in $Computers) {
    Get-WinEvent -ComputerName $Computer -FilterHashtable @{
        ProviderName = @("Microsoft-Windows-Security-Auditing","Microsoft-Windows-Winlogon")
        Id           = @(4800, 4801,7001,7002)
        StartTime    = $Script.StartTime.AddDays(-$Days)
    }  |ForEach-Object { [Void]$Script.Events.Add($_) }
}

$Results = New-Object System.Collections.ArrayList
ForEach ($Event in $Script.Events) {
    ForEach ($Line in ($Test4 -split "`r`n")) {
        IF ([String]::IsNullOrWhiteSpace($Line)) { continue }
        Switch -Wildcard ($Line.Trim()) {
            "Security ID:*"    {$nSecurityID    = ($_ -split "Security ID:")[1].trim()}
            "Account Name:*"   {$nAccountName   = ($_ -split "Account Name:")[1].trim()}
            "Account Domain:*" {$nAccountDomain = ($_ -split "Account Domain:")[1].trim()}
            "Session ID:*"     {$nSessionID     = ((($_ -split "Session ID:")[1]).split(";")[0]).Trim()}
        }
    }
    Switch ($Event.ID) {
        4800 {$nMessage = "The workstation was locked."}
        4801 {$nMessage = "The workstation was unlocked."}
        7001 {$nMessage = "User Logon."}
        7002 {$nMessage = "User Logoff."}

    }
    [Void]$Results.Add([PSCustomObject]@{
        SID           = $nSecurityID
        AccountName   = $nAccountName
        AccountDomain = $nAccountDomain
        SessionID     = $nSessionID
        EventID       = $Event.Id
        Message       = $nMessage
        TimeCreated   = $Event.TimeCreated
        LogName       = $Event.LogName
        ComputerName  = $Event.MachineName
    })
    Remove-Variable -Name @("Event","nSecurityID","nAccountName","nAccountDomain","nSessionID","nMessage") -ErrorAction SilentlyContinue
}
$Results
Remove-Variable -Name @("Script","Results") -ErrorAction SilentlyContinue
