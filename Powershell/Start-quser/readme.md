[![Generic badge](https://img.shields.io/badge/Script%20Version-v1.0-Green.svg)](#) [![Generic badge](https://img.shields.io/badge/Maintained-Yes-Green.svg)](#) [![Generic badge](https://img.shields.io/badge/Minimum%20PS%20Version-3.0-Green.svg)](#) [![GPLv3 license](https://img.shields.io/badge/License-GPLv3-blue.svg)](http://perso.crans.org/besson/LICENSE.html)

### SYNOPSIS
Powershell wrapper for quser to display information about user sessions on a system.

### DESCRIPTION
A powershell wrapper for quser that allows the application to be easily run against multiple systems and converts the results to a easily usable arraylist.

### PARAMETER Servers
Accepts a string list of computers and will run quser application against each of them. 

### EXAMPLE
  PS C:\Windows\system32> start-quser

  Hostname     : COMPUTER-SS8I7
  USERNAME     : HellBomb
  SESSIONNAME  : console
  ID           : 1
  STATE        : Active
  LogonTime    : 6/20/2020 2:17:00 PM
  TotalMinutes : 11304

### EXAMPLE
  PS C:\Windows\system32> start-quser |ft

  Hostname     USERNAME SESSIONNAME ID STATE  LogonTime            TotalMinutes
  --------     -------- ----------- -- -----  ---------            ------------
  UCFO-6CWRWT2 nrwaril  console     1  Active 6/20/2020 2:17:00 PM        11306

### NOTES
VERSION     DATE			NAME						DESCRIPTION
___________________________________________________________________________________________________________
1.0         28 June 2020	Warilia, Nicholas R.		Initial version

Credits:
(1) Script Template: https://gist.github.com/9to5IT/9620683
