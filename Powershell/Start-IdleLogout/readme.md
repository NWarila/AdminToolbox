[![Generic badge](https://img.shields.io/badge/Script%20Version-v1.0-Green.svg)](#) [![Generic badge](https://img.shields.io/badge/Maintained-Yes-Green.svg)](#) [![Generic badge](https://img.shields.io/badge/Minimum%20PS%20Version-3.0-Green.svg)](#) [![GPLv3 license](https://img.shields.io/badge/License-GPLv3-blue.svg)](http://perso.crans.org/besson/LICENSE.html)

### .SYNOPSIS
When combined with scheduled tasks, logoff inactive users after specified time. 

### .DESCRIPTION
Intended to be used with Scheduled Task triggered on session lock to disconnect a user after a specified amount of time. Script will query registry to find if GPO setting "Set time limit for disconnected sessions" is configured and will logoff locked sessions that exceed that time.


### .NOTES
    VERSION     DATE			NAME						DESCRIPTION
	___________________________________________________________________________________________________________
	1.0     30 June 2020		Nick W.						Initial version

	License: GPLv3
	Min PS Ver: 3.0
	Script Repo: https://github.com/HellBomb/AdminToolbox/tree/master/Powershell/Start-IdleLogout
    Credits:
        (1) Script Template: https://gist.github.com/9to5IT/9620683

