Function Start-QUser {
<#
    .SYNOPSIS
        Powershell wrapper for quser to display information about user sessions on a system.

    .DESCRIPTION
        A powershell wrapper for quser that allows the application to be easily run against multiple systems and converts the results to a easily usable arraylist.

    .PARAMETER Servers
        Accepts a string list of computers and will run quser application against each of them. 

    .INPUTS
        None

    .OUTPUTS
        None

    .EXAMPLE
        PS C:\Windows\system32> start-quser

        Hostname     : COMPUTER-SS8I7
        USERNAME     : HellBomb
        SESSIONNAME  : console
        ID           : 1
        STATE        : Active
        LogonTime    : 6/20/2020 2:17:00 PM
        TotalMinutes : 11304

    .EXAMPLE
        PS C:\Windows\system32> start-quser |ft

        Hostname     USERNAME SESSIONNAME ID STATE  LogonTime            TotalMinutes
        --------     -------- ----------- -- -----  ---------            ------------
        UCFO-6CWRWT2 nrwaril  console     1  Active 6/20/2020 2:17:00 PM        11306

    .NOTES
    VERSION     DATE			NAME						DESCRIPTION
	___________________________________________________________________________________________________________
	1.0         28 June 2020	Warilia, Nicholas R.		Initial version

    Credits:
        (1) Script Template: https://gist.github.com/9to5IT/9620683

#>
    Param (
        [String]$Servers = $env:COMPUTERNAME
    )

    <# One Liner that does roughly the same thing about 30MS faster.
    (quser) -replace '\s{2,}',',' -replace ">" | ConvertFrom-Csv |
            Select-Object @{Name="Hostname";Expression={$env:Computername}},UserName,SessionName,ID,State,
                          @{Name="LogonTime";Expression={[DateTime]$_."Logon Time"}},
                          @{Name="TotalMinutes";Expression={[math]::Round((New-TimeSpan ([DateTime]$_."Logon Time") ($DateTime)).TotalMinutes)}}
    #>

    $DateTime = [DateTime]::Now
    $Results = [System.Collections.ArrayList]::new()
    ForEach ($Server in $Servers) {
        $Process = [System.Diagnostics.Process]::new()
        $Process.StartInfo = [System.Diagnostics.ProcessStartInfo]::new()
        IF ($Server -match $env:COMPUTERNAME) {
            $Process.StartInfo.Arguments = ""
        } Else {
            $Process.StartInfo.Arguments = "/server:$Server"
        }
        $Process.StartInfo.FileName = "$($env:windir)\System32\quser.exe"
        $Process.StartInfo.UseShellExecute = $False
        $Process.StartInfo.CreateNoWindow  = $True
        $Process.StartInfo.RedirectStandardOutput = $True
        $Process.StartInfo.RedirectStandardError = $False
        $Process.StartInfo.RedirectStandardInput = $False
        $Process.StartInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
        $Process.StartInfo.LoadUserProfile = $False
        [Void]$Process.Start()
        [Void]$Process.WaitForExit()
        
        
        #Convert StandardOutput into desired format.
        [Void]$Results.Add(($Process.StandardOutput.ReadToEnd() -split "`r`n" -replace '\s{2,}',',' -replace ">" | ConvertFrom-Csv |
            Select-Object @{Name="Hostname";Expression={$Server}},UserName,SessionName,ID,State,
                          @{Name="LogonTime";Expression={[DateTime]$_."Logon Time"}},
                          @{Name="TotalMinutes";Expression={[math]::Round((New-TimeSpan ([DateTime]$_."Logon Time") ($DateTime)).TotalMinutes)}}))
        [Void]$Process.Dispose()
    }
    Return $Results
}
Start-QUser
