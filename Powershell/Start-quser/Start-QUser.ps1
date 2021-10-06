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
            
        .EXAMPLE
            PS C:\Windows\system32> start-quser -Servers $env:COMPUTERNAME,"COMP-RDS01","COMP-DC01","COMP-713V3TW","COMP-T217VT3" |ft
            Hostname     USERNAME SESSIONNAME ID STATE  LogonTime            TotalMinutes
            --------     -------- ----------- -- -----  ---------            ------------
            COMP-713V3TW nrwaril  console     1  Active 6/20/2020 2:17:00 PM        11328
            COMP-T217VT3 nrwaril  console     4  Active 5/11/2020 8:42:00 AM        69263
            UCFO-72T1VT3 nrwaril  console     8  Active 5/19/2020 9:46:00 AM        57679
            
        .NOTES
        VERSION     DATE			NAME						DESCRIPTION
	    ___________________________________________________________________________________________________________
	    1.0         28 June 2020	Warilia, Nicholas R.		Initial version
        Credits:
            (1) Script Template: https://gist.github.com/9to5IT/9620683
    #>
    Param (
        [String[]]$Servers = $env:COMPUTERNAME
    )

    New-Variable -Force -ErrorAction:'Stop' -Name NVSplat -Value @{'Force'=$True;'ErrorAction'='Stop'}
    New-Variable @NVSplat -Name:'Results'  -Value:(New-Object -TypeName:'System.Collections.ArrayList')
    New-Variable @NVSplat -Name:'DateTime' -Value:([DateTime]::Now)

    ForEach ($Server in $Servers) {
        New-Variable @NVSplat -Name:'Process' -Value:(New-Object -TypeName:'System.Diagnostics.Process')
        $Process.StartInfo = New-Object -TypeName:'System.Diagnostics.ProcessStartInfo'
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
        ($Process.StandardOutput.ReadToEnd() -split "`r`n" -replace '\s{2,}',',' -replace ">" | 
        ConvertFrom-Csv | ForEach-Object {
            $Null = $Results.Add([PSCustomObject]@{
                HostName = $Server
                Username = $_.UserName
                SessionName = $_.SessionName
                ID = $_.ID
                State = $_.State
                LogonTime = [DateTime]$_."Logon Time"
                TotalMinutes = [math]::Round((New-TimeSpan -Start ([DateTime]$_."Logon Time") -End ($DateTime)).TotalMinutes)
            })
        })
        [Void]$Process.Dispose()
    }

    Return ,$Results
}
