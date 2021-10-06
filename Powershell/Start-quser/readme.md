[![Generic badge](https://img.shields.io/badge/Script%20Version-v1.0-Green.svg)](#) [![Generic badge](https://img.shields.io/badge/Maintained-Yes-Green.svg)](#) [![Generic badge](https://img.shields.io/badge/Minimum%20PS%20Version-3.0-Green.svg)](#) [![GPLv3 license](https://img.shields.io/badge/License-GPLv3-blue.svg)](http://perso.crans.org/besson/LICENSE.html)

### .SYNOPSIS
Powershell wrapper for quser to display information about user sessions on a system.

### .DESCRIPTION
A powershell wrapper for quser that allows the application to be easily run against multiple systems and converts the results to a easily usable arraylist.

### .PARAMETER Servers
Accepts a string list of computers and will run quser application against each of them. 

### .NOTES
    VERSION     DATE			NAME					DESCRIPTION
    ___________________________________________________________________________________________________________
    1.0         28 June 2020	        Warilia, Nicholas R.		        Initial version

    Credits:
    (1) Script Template: https://gist.github.com/9to5IT/9620683

### EXAMPLE 1
    PS C:\Windows\system32> start-quser

    Hostname     : COMPUTER-SS8I7
    USERNAME     : nrwaril
    SESSIONNAME  : console
    ID           : 1
    STATE        : Active
    LogonTime    : 6/20/2020 2:17:00 PM
    TotalMinutes : 11304

### EXAMPLE 2
    PS C:\Windows\system32> start-quser |ft

    Hostname     USERNAME SESSIONNAME ID STATE  LogonTime            TotalMinutes
    --------     -------- ----------- -- -----  ---------            ------------
    COMPUTER-SS8I7 nrwaril  console     1  Active 6/20/2020 2:17:00 PM        11306
    
### EXAMPLE 3
    Hostname     USERNAME SESSIONNAME ID STATE  LogonTime            TotalMinutes
    --------     -------- ----------- -- -----  ---------            ------------
    COMP-713V3TW nrwaril  console     1  Active 6/20/2020 2:17:00 PM        11328
    COMP-T217VT3 nrwaril  console     4  Active 5/11/2020 8:42:00 AM        69263
    UCFO-72T1VT3 nrwaril  console     8  Active 5/19/2020 9:46:00 AM        57679



One Liner that does roughly the same thing about 30MS faster.

    (quser) -replace '\s{2,}',',' -replace ">" | ConvertFrom-Csv |
            Select-Object @{Name="Hostname";Expression={$env:Computername}},UserName,SessionName,ID,State,
                            @{Name="LogonTime";Expression={[DateTime]$_."Logon Time"}},
                            @{Name="TotalMinutes";Expression={[math]::Round((New-TimeSpan ([DateTime]$_."Logon Time") ($DateTime)).TotalMinutes)}}
