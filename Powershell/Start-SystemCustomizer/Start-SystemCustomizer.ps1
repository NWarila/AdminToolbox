Function Start-SystemCustomizer {
    <#
        .SYNOPSIS
            This script is used to customize windows 10 systems and profiles and slowly document what options are available. As a system administrator it can be quite frustrating to log into system after system and have many setting change between sessions and this allows easy standardization of these settings.

        .DESCRIPTION
            
        .PARAMETER TargetUser
            
            CurrentUser
            DefaultUser
            Both

        .PARAMETER MinimizedStateTabletModeOff
            [Int] Used to determine the default state of the ribbon in explorer when tablet mode is off.
                0 = Expanded
                1 = Minimized

        .PARAMETER MinimizedStateTabletModeOn
            [Int] Used to determine the default state of the ribbon in explorer when tablet mode is on.
                0 = Expanded
                1 = Minimized

        .PARAMETER WindowsFeedbackFrequency
            [String] Change how frequently Windows should ask for feedback.
                Automatically
                Never
                Always
                Daily
                Weekly

        .PARAMETER LetAppsActivateWithVoiceCU
            [Int] Specifies if Windows apps can be activated by voice.
                0 = Windows apps cannot be activated by voice.
                1 = Windows apps can be activated by voice.

        .PARAMETER LetAppsActivateWithVoiceAboveLockCU
            [Int] Specifies if Windows apps can be activated by voice while the screen is locked.
                0 =  Windows apps cannot be activated by voice while the screen is locked.
                1 =  Windows apps can be activated by voice while the screen is locked.
        
        .PARAMETER DisableAdvertisingIdCU
        [Int] (System Setting) Added in Windows 10, version 1607. Enables or disables the Advertising ID for the current user.

        .PARAMETER Confirm
            [Int] Determine what type of changes should be prompted before executing.
                0 - Confirm both environment and object changes.
                1 - Confirm only object changes. (Default)
                2 - Confirm nothing!
                Object Changes are changes that are permanent such as file modifications, registry changes, etc.
                Environment changes are changes that can normally be restored via restart, such as opening/closing applications.
                Note: This configuration will take priority over Debugger settings for confirm action preference.

        .PARAMETER TimeZone
            [String] (System Setting) Configure your time zone. To get a full list of time zones using 'Get-TimeZone -ListAvailable |Select ID'
        
        .PARAMETER DoNotShowFeedbackNotifications
            [Int] (System Setting) Configure Windows Feedback Notifications
                0 = Enable Windows Feedback Notifications
                1 = Disable Windows Feedback Notifications
        
        .PARAMETER LetAppsActivateWithVoiceAllUsers
            [Int] (System Setting) Specifies if Windows apps can be activated by voice.
                0 = User in control. Users can decide if Windows apps can be activated by voice using Settings > Privacy options on the device.
                1 = Force allow. Windows apps can be activated by voice and users cannot change it.
                2 = Force deny. Windows apps cannot be activated by voice and users cannot change it.
        
        .PARAMETER LetAppsActivateWithVoiceAboveLockAllUsers
            [Int] (System Setting) Specifies if Windows apps can be activated by voice while the screen is locked.
                0 = User in control. Users can decide if Windows apps can be activated by voice while the screen is locked using Settings > Privacy options on the device.
                1 = Force allow. Windows apps can be activated by voice while the screen is locked, and users cannot change it.
                2 = Force deny. Windows apps cannot be activated by voice while the screen is locked, and users cannot change it.
        
        .PARAMETER AllowCrossDeviceClipboard
            [Int] (System Setting) Added in Windows 10, version 1809. Specifies whether clipboard items roam across devices. When this is allowed, an item copied to the clipboard is uploaded to the cloud so that other devices can access. Also, when this is allowed, a new clipboard item on the cloud is downloaded to a device so that user can paste on the device.
                0 = Not allowed
                1 = Allowed

        .PARAMETER OnlineSpeechRecognition
            [Int] (System Setting) Updated in Windows 10, version 1809. This policy specifies whether users on the device have the option to enable online speech recognition. When enabled, users can use their voice for dictation and to talk to Cortana and other apps that use Microsoft cloud-based speech recognition. Microsoft will use voice input to help improve our speech services. If the policy value is set to 0, online speech recognition will be disabled and users cannot enable online speech recognition via settings. If policy value is set to 1 or is not configured, control is deferred to users.
                0 = Not allowed
                1 = Allowed
        
        .PARAMETER DisableAdvertisingId
        [Int] (System Setting) Added in Windows 10, version 1607. Enables or disables the Advertising ID.

        .PARAMETER Debugger
            [Int] Used primarily to quickly apply multiple arguments making script development and debugging easier. Useful only for developers.
                1. Incredibly detailed play-by-play execution of the script. Equivilent to '-Change 0',  '-LogLevel Verbose', script wide 'ErrorAction Stop', 'Set-StrictMode -latest', and lastly 'Set-PSDebug -Trace 1'
                2. Equivilent to '-Change 0', '-LogLevel Verbose', and script wide 'ErrorAction Stop'.
                3. Equivilent to '-Change 1', '-LogLevel Info', and enables verbose on PS commands.

        .PARAMETER LogLevel
            [String] Used to display log output with definitive degrees of verboseness. 
                Verbose = Display everything the script is doing with extra verbose messages, helpful for debugging, useless for everything else.
                Debug   = Display all messages at a debug or higher level, useful for debugging.
                Info    = Display all informational messages and higher. (Default)
                Warn    = Display only warning and error messages.
                Error   = Display only error messages.
                None    = Display absolutely nothing.

        .INPUTS
            None

        .OUTPUTS
            None

        .NOTES
        VERSION     DATE			NAME						DESCRIPTION
	    ___________________________________________________________________________________________________________
	    1.0         28 Sept 2020	Warilia, Nicholas R.		Initial version
        2.0         08 Oct 2020 	Warilia, Nicholas R.		Applied standard PS framework, skipped disabled user accounts, added 
                                                                description modification for site 11, and only uses description if it
                                                                starts with "site [0-9]+"
        
        Script tested on the following Powershell Versions
         1.0   2.0   3.0   4.0   5.0   5.1 
        ----- ----- ----- ----- ----- -----
          X    X      X     X     ✓    ✓

        Credits:
            (1) Script Template: https://gist.github.com/9to5IT/9620683

        To Do List:
            (1) Get Powershell Path based on version (stock powershell, core, etc.)

        Research/Additional Information
            (1) https://docs.microsoft.com/en-us/windows/privacy/manage-connections-from-windows-operating-system-components-to-microsoft-services
            (2) https://www.tenforums.com/tutorials/130122-allow-deny-apps-access-use-voice-activation-windows-10-a.html
            (3) https://gist.github.com/goyuix/fd68db59a4f6355ee0f6
            (4) https://stackoverflow.com/questions/31620763/no-garbage-collection-while-powershell-pipeline-is-executing
    #>

    [CmdletBinding(
        ConfirmImpact="None",
        DefaultParameterSetName="Default",
        HelpURI="",
        SupportsPaging=$False,
        SupportsShouldProcess=$False,
        PositionalBinding=$True
    )] Param (
        [ValidateSet("CurrentUser","Both","DefaultUser")]
        $TargetUser,
        [ValidateSet(0,1)]
        $MinimizedStateTabletModeOff=0,
        [ValidateSet(0,1)]
        $MinimizedStateTabletModeOn=0,
        [ValidateSet("Automatically","Never","Always","Daily","Weekly")]
        $WindowsFeedbackFrequency = "Never",
        [ValidateSet(0,1)]
        $LetAppsActivateWithVoiceCU,
        [ValidateSet(0,1)]
        $LetAppsActivateWithVoiceAboveLockCU,
        #System Configration
        $TimeZone = "Eastern Standard Time",
        [ValidateSet(0,1)]
        $DoNotShowFeedbackNotifications,
        [ValidateSet(0,1,2)]
        $LetAppsActivateWithVoiceAllUsers,
        [ValidateSet(0,1,2)]
        $LetAppsActivateWithVoiceAboveLockAllUsers,
        [ValidateSet(0,1)]
        $AllowCrossDeviceClipboard,
        [ValidateSet(0,1)]
        $OnlineSpeechRecognition,
        [ValidateSet(0,1,2)]
        [Int]$Confim = 1,
        [ValidateSet(0,1,2)]
        [Int]$Debugger = 3,
        [ValidateSet("Verbose","Debug","Info","Warn","Error","Fatal","Off")]
        [String]$LogLevel = "Info",
        [Switch]$WhatIf
    )

    # ---------------------------------------------------- [Manual Configuration] ----------------------------------------------------
    #Require Admin Privilages.
    New-Variable -Name ScriptConfig -Force -ErrorAction Stop -value @{
        #Should script enforce running as admin.
        RequireAdmin = $False
    }

    #User Configurations
    $LetAppsActivateWithVoiceCU = 0
    $LetAppsActivateWithVoiceAboveLockCU = 0

    #System Configurations
    $DoNotShowFeedbackNotifications
    $LetAppsActivateWithVoiceAllUsers = 2
    $LetAppsActivateWithVoiceAboveLockAllUsers = 2
    $AllowCrossDeviceClipboard = 0
    $OnlineSpeechRecognition = 0

    #------------------------------------------------------ [Required Functions] -----------------------------------------------------
    #Settting requirements to run the script can help ensure script execution consistency.
    #About #Requires: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_requires?view=powershell-5.1
    #Requires -Version 5.1
    #Requires -PSEdition Desktop

    Function local:Write-nLog {
        <#
            .SYNOPSIS
                Standardized & Easy to use logging function.
            .DESCRIPTION
                Easy and highly functional logging function that can be dropped into any script to add logging capability without hindering script performance.
            .PARAMETER type
                Set the event level of the log event.
                [Options]
                    Info, Warning, Error, Debug
        
            .PARAMETER message
                Set the message text for the event.
            .PARAMETER ErrorCode
                Set the Error code for Error & fatal level events. The error code will be displayed in front of the message text for the event.
            
            .PARAMETER WriteHost
                Force writing to host reguardless of SetWriteLog setting for this specific instance.
            .PARAMETER WriteLog
                Force writing to log reguardless of SetWriteLog setting for this specific instance.
            .PARAMETER SetLogLevel
                Set the log level for the nLog function for all future calls. When setting a log level all logs at 
                the defined level will be logged. If you set the log level to warning (default) warning messages 
                and all events above that such as error and fatal will also be logged. 
                (1) Debug: Used to document events & actions within the script at a very detailed level. This level 
                is normally used during script debugging or development and is rarely set once a script is put into
                production
                (2) Information: Used to document normal application behavior and milestones that may be useful to 
                keep track of such. (Ex. File(s) have been created/removed, script completed successfully, etc)
                (3) Warning: Used to document events that should be reviewed or might indicate there is possibly
                unwanted behavior occuring.
                (4) Error: Used to document non-fatal errors indicating something within the script has failed.
                (5) Fatal: Used to document errors significant enough that the script cannot continue. When fatal
                errors are called with this function the script will terminate. 
        
                [Options]
                    1,2,3,4,5
            .PARAMETER SetLogFile
                Set the fully quallified path to the log file you want used. If not defined, the log will use the 
                "$Env:SystemDrive\ProgramData\Scripts\Logs" directory and will name the log file the same as the 
                script name. 
            .PARAMETER SetWriteHost
                Configure if the script should write events to the screen. (Default: $False)
                [Options]
                    $True,$False
        
            .PARAMETER SetWriteLog
                Configure if the script should write events to the screen. (Default: $True)
                [Options]
                    $True,$False
        
            .PARAMETER Close
                Removes all script-level variables set while nLog creates while running.
            .INPUTS
                None
            .OUTPUTS
                None
            .NOTES
            VERSION     DATE			NAME						DESCRIPTION
	        ___________________________________________________________________________________________________________
	        1.0			25 May 2020		Warila, Nicholas R.			Initial version
            2.0			28 Aug 2020		Warila, Nicholas R.			Complete rewrite of major portions of the script, significant improvement in script performance (about 48%), and updated log format.
        
            Credits:
                (1) Script Template: https://gist.github.com/9to5IT/9620683
        #>
        Param (
            [Parameter(Mandatory=$True,Position=0)]
            [ValidateSet('Debug','Info','Warning','Error','Fatal')]
            [String]$Type,
            [Parameter(Mandatory=$True,ValueFromPipeline=$False,Position=1)]
            [String]$Message,
            [Parameter(Mandatory=$False,ValueFromPipeline=$False,Position=2)][ValidateRange(0,9999)]
            [Int]$ErrorCode = 0,
            [Switch]$WriteHost,
            [Switch]$WriteLog,
            [Switch]$Initialize,
            [Parameter(Mandatory=$False,ValueFromPipeline=$False)][ValidateRange(0,5)]
            [Int]$SetLogLevel,
            [Parameter(Mandatory=$False,ValueFromPipeline=$False)]
            [String]$SetLogFile,
            [Parameter(Mandatory=$False,ValueFromPipeline=$False)]
            [String]$SetLogDir,
            [Parameter(Mandatory=$False,ValueFromPipeline=$False)]
            [Bool]$SetWriteHost,
            [Parameter(Mandatory=$False,ValueFromPipeline=$False)]
            [Bool]$SetWriteLog,
            [Parameter(Mandatory=$False,ValueFromPipeline=$False)]
            [ValidateSet('Local','UTC')]
            [String]$SetTimeLocalization,
            [ValidateSet('nLog','CMTrace')]
            [String]$SetLogFormat,
            [Switch]$Close
        )

        #Best practices to ensure function works exactly as expected, and prevents adding "-ErrorAction Stop" to so many critical items.
        #$Local:ErrorActionPreference = 'Stop'
        #Set-StrictMode -Version Latest

        #Allows us to turn on verbose on all powershell commands when adding -verbose
        IF ($PSBoundParameters.ContainsKey('Verbose')) {
            Set-Variable -Name Verbose -Value $True
        } Else {
            Set-Variable -Name Verbose -Value ([Bool]$Script:Verbose)
        }

        New-Variable -Name StartTime -Value ([DateTime]::Now) -Force -Verbose:$Verbose -Description "Used to calculate timestamp differences between log calls."

        #Ensure all the required script-level variables are set.
        IF ((-Not (Test-Path variable:Script:nLogInitialize)) -OR $Initialize) {
            New-Variable -Name SetTimeLocalization -Verbose:$Verbose -Scope Script -Force -Value ([DateTime]::Now)
            New-Variable -Name nLogFormat          -Verbose:$Verbose -Scope Script -Force -Value "nLog"
            New-Variable -Name nLogLevel           -Verbose:$Verbose -Scope Script -Force -Value ([Int]3)
            New-Variable -Name nLogInitialize      -Verbose:$Verbose -Scope Script -Force -Value $True
            New-Variable -Name nLogWriteHost       -Verbose:$Verbose -Scope Script -Force -Value $False
            New-Variable -Name nLogWriteLog        -Verbose:$Verbose -Scope Script -Force -Value $True
            New-Variable -Name nLogDir             -Verbose:$Verbose -Scope Script -Force -Value $Env:TEMP
            New-Variable -Name nLogLastTimeStamp   -Verbose:$Verbose -Scope Script -Force -Value $StartTime
            New-Variable -Name nLogFileValid       -Verbose:$Verbose -Scope Script -Force -Value $False
            If ([String]::IsNullOrEmpty([io.path]::GetFileNameWithoutExtension($script:MyInvocation.MyCommand.path))) {
                New-Variable -Name nLogFile -Scope Script -Force -Verbose:$Verbose -Value "Untitled.log"
            } Else {
                New-Variable -Name nLogFile -Scope Script -Force -Verbose:$Verbose -Value "$([io.path]::GetFileNameWithoutExtension($script:MyInvocation.MyCommand.path))`.log"
            }
            New-Variable -Name nLogFullName      -Verbose:$Verbose -Scope Script -Force -Value (Join-Path -Path $Script:nLogDir -ChildPath $Script:nLogFile)
            New-Variable -Name nLogLevels        -Verbose:$Verbose -Scope Script -Force -Value $([HashTable]@{
                Debug   = @{ Text = "[DEBUG]  "; LogLevel = [Int]'1'; tForeGroundColor = "Cyan";   }
                Info    = @{ Text = "[INFO]   "; LogLevel = [Int]'2'; tForeGroundColor = "White";  }
                Warning = @{ Text = "[WARNING]"; LogLevel = [Int]'3'; tForeGroundColor = "DarkRed";}
                Error   = @{ Text = "[ERROR]  "; LogLevel = [Int]'4'; tForeGroundColor = "Red";    }
                Fatal   = @{ Text = "[FATAL]  "; LogLevel = [Int]'5'; tForeGroundColor = "Red";    }
            })
        }

        #Initalize of the variables.
        IF ($PSBoundParameters.ContainsKey('SetLogLevel')) {
            Set-Variable -Name nLogLevel     -Verbose:$Verbose -Scope Script -Force -Value $SetLogLevel
        }
        IF ($PSBoundParameters.ContainsKey('SetLogFormat')) {
            Set-Variable -Name nLogFormat     -Verbose:$Verbose -Scope Script -Force -Value $SetLogFormat
        }
        IF ($PSBoundParameters.ContainsKey('SetWriteHost')) {
            Set-Variable -Name nLogWriteHost -Verbose:$Verbose -Scope Script -Force -Value $SetWriteHost
        }
        IF ($PSBoundParameters.ContainsKey('SetWriteLog')) {
            Set-Variable -Name nLogWriteLog  -Verbose:$Verbose -Scope Script -Force -Value $SetWriteLog
        }
        IF ($PSBoundParameters.ContainsKey('SetLogDir')) {
            Set-Variable -Name nLogDir       -Verbose:$Verbose -Scope Script -Force -Value $SetLogDir
            Set-Variable -Name nLogFileValid -Verbose:$Verbose -Scope Script -Force -Value $False
        }
        IF ($PSBoundParameters.ContainsKey('SetLogFile')) {
            Set-Variable -Name nLogFile      -Verbose:$Verbose -Scope Script -Force -Value "$($SetLogFile -replace "[$([string]::join('',([System.IO.Path]::GetInvalidFileNameChars())) -replace '\\','\\')]",'_')"
            Set-Variable -Name nLogFileValid -Verbose:$Verbose -Scope Script -Force -Value $False
        }
        IF ($PSBoundParameters.ContainsKey('SetTimeLocalization')) {
            #Prevent issues where timestamp will show huge differences in time between code calls when converting UCT and Local
            If ($Script:nLogTimeLocalization -ne $SetTimeLocalization -AND -NOT [String]::IsNullOrWhiteSpace($Script:nLogLastTimeStamp)) {
                If ($Script:nLogTimeLocalization -eq 'Local') {
                    Set-Variable -Name nLogLastTimeStamp -Verbose:$Verbose -Scope Script -Force -Value $nLogLastTimeStamp.ToLocalTime()
                } Else {
                    Set-Variable -Name nLogLastTimeStamp -Verbose:$Verbose -Scope Script -Force -Value $nLogLastTimeStamp.ToUniversalTime()
                }
            }
            Set-Variable -Name nLogTimeLocalization -Verbose:$Verbose -Scope Script -Force -Value $SetTimeLocalization
        }

        IF ($PSBoundParameters.ContainsKey('WriteHost')) { $tWriteHost = $True } Else { $tWriteHost = $Script:nLogWriteHost }
        IF ($PSBoundParameters.ContainsKey('WriteLog'))  { $tWriteLog  = $True } Else { $tWriteLog  = $Script:nLogWriteLog  }

        #Determine if script log level greater than or equal to current log event level and we actually are configured to write something.
        IF ($Script:nLogLevels[$Type]["LogLevel"] -ge $Script:nLogLevel -AND $Script:nLogLevel -ne 0 -AND ($tWriteHost -EQ $True -OR $tWriteLog -EQ $True)) {

            #Convert TimeStamp if needed
            IF ($Script:nLogTimeLocalization -eq 'UTC') {
                Set-Variable -Name StartTime -Value ($StartTime.ToUniversalTime().ToString("s",[System.Globalization.CultureInfo]::InvariantCulture))
            }

            #Code Block if writing out to log file.
            if ($tWriteLog) {
                IF ($Script:nLogFileValid -eq $False) {
                    Set-Variable -Name nLogFullName      -Verbose:$Verbose -Scope Script -Force -Value (Join-Path -Path $Script:nLogDir -ChildPath $Script:nLogFile)
                    If ([System.IO.File]::Exists($Script:nLogFullName)) {
                        Set-Variable -Name nLogFileValid -Verbose:$Verbose -Scope Script -Force -Value $True
                    } Else {
                        New-Item -Path $Script:nLogFullName -Force -Verbose:$Verbose
                        Set-Variable -Name nLogFileValid -Verbose:$Verbose -Scope Script -Force -Value $True
                    }
                }
                $StreamWriter = [System.IO.StreamWriter]::New($Script:nLogFullName,$True,([Text.Encoding]::UTF8))
                
                Switch ($Script:nLogFormat) {
                    'CMTrace'    {
                        [String]$WriteLine = '<![LOG[{0}]LOG]!><time="{1}" date="{2}" component="{3}" context="" type="{4}" thread="" file="">' -f `
                        $Message,
                        ([DateTime]$StartTime).ToString('HH:mm:ss.fff+000'),
                        ([DateTime]$StartTime).ToString('MM-dd-yyyy'),
                        "$($ScriptEnv.ScriptFullName.name):$($MyInvocation.ScriptLineNumber)",
                        "1"
                    }
                    'nLog' {
                        $WriteLine = "$StartTime||$Env:COMPUTERNAME||$Type||$($ErrorCode.ToString(`"0000`"))||$($MyInvocation.ScriptLineNumber)||$Message"
                    }
                }
                
                $StreamWriter.WriteLine($WriteLine)
                $StreamWriter.Close()
            }

            #Code Block if writing out to log host.
            IF ($tWriteHost) {
                Write-Host -ForegroundColor $Script:nLogLevels[$Type]["tForeGroundColor"] -Verbose:$Verbose "$StartTime ($(((New-TimeSpan -Start $Script:nLogLastTimeStamp -End $StartTime -Verbose:$Verbose).Seconds).ToString('0000'))s) $($Script:nLogLevels[$Type]['Text']) [$($ErrorCode.ToString('0000'))] [Line: $($MyInvocation.ScriptLineNumber.ToString('0000'))] $Message"
            }
                
            #Ensure we have the timestamp of the last log execution.
            Set-Variable -Name nLogLastTimeStamp -Scope Script -Value $StartTime -Force -Verbose:$Verbose
        }
        
        #Remove Function Level Variables. This isn't needed unless manually running portions of the code instead of calling it via a funtion.
        #Remove-Variable -Name @("Message","SetLogLevel","SetLogFile","Close","SetWriteLog","SetWriteHost","LineNumber","ErrorCode","tWriteHost","WriteHost","tWriteLog","WriteLog","StartTime") -ErrorAction SilentlyContinue

        IF ($PSBoundParameters.ContainsKey('Close') -or $Type -eq 'Fatal') {
            Remove-Variable -Name @("nLogLastTimeStamp","nLogFileValid","nLogFile","nLogDir","nLogWriteLog","nLogWriteHost","nLogInitialize","nLogLastTimeStamp","nLogLevels","nLogFullName","nLogLevel") -Scope Script -ErrorAction SilentlyContinue
        }

        #Allow us to exit the script from the logging function.
        If ($Type -eq 'Fatal') {
            Exit
        }
    }
    Function local:Set-RegistryKey {
        <#
            .SYNOPSIS
                Used to set registry key value.

            .DESCRIPTION
                Robust function used to set a registry value with error handling and logging.
            
            .PARAMETER RegistryHive
                [String] Used to determine the default state of the ribbon in explorer when tablet mode is off.
                    HKEY_USERS            = 
                    HKEY_CLASSES_ROOT     = 
                    HKEY_CURRENT_CONFIG   = 
                    HKEY_CURRENT_USER     = 
                    HKEY_LOCAL_MACHINE    =

            .PARAMETER DataType
                [String] Used to determine the default state of the ribbon in explorer when tablet mode is on.
                    REG_BINARY    = Raw binary data. Most hardware component information is stored as binary data and is displayed in Registry Editor in hexadecimal format.
                    REG_DWORD     = Data represented by a number that is 4 bytes long (a 32-bit integer). Many parameters for device drivers and services are this type and are displayed in Registry Editor in binary, hexadecimal, or decimal format. Related values are DWORD_LITTLE_ENDIAN (least significant byte is at the lowest address) and REG_DWORD_BIG_ENDIAN (least significant byte is at the highest address).
                    REG_EXPAND_SZ = A variable-length data string. This data type includes variables that are resolved when a program or service uses the data.
                    REG_MULTI_SZ  = A multiple string. Values that contain lists or multiple values in a form that people can read are generally this type. Entries are separated by spaces, commas, or other marks.
                    REG_SZ        = A fixed-length text string.
                    REG_QWORD	  = Data represented by a number that is a 64-bit integer. This data is displayed in Registry Editor as a Binary Value and was introduced in Windows 2000.
                    REG_NONE      = Data without any particular type. This data is written to the registry by the system or applications and is displayed in Registry Editor in hexadecimal format as a Binary Value
            
            .PARAMETER CreateKey
                [Bool] Create the registry key if the key does not exist. This does not affect key properties/values, this only affects if the key containing the value should be created if it does not already exists.
                    True  = Create the key if the key does not already exists. (Default)
                    False = Do not create the key if it does not exist.

            .PARAMETER FixDataType
                [Bool] Determines if the script will update the DataType in the regsitry if the current item property doesn't match what the script thinks it should be.
                    True  = Remove and recreate item property if it doesn't match what the script thinks it should be.
                    False = Leave the item properties data type the same and just update the value. (Default)

            .PARAMETER Confirm
                [Int] Determine what type of changes should be prompted before executing.
                    0 - Confirm both environment and object changes.
                    1 - Confirm only object changes.
                    2 - Confirm nothing! (Default)
                    Object Changes are changes that are permanent such as file modifications, registry changes, etc.
                    Environment changes are changes that can normally be restored via restart, such as opening/closing applications.

            .INPUTS
                None

            .OUTPUTS
                None

            .NOTES
            VERSION     DATE			NAME						DESCRIPTION
	        ___________________________________________________________________________________________________________
	        1.0         01 April 2021	Warilia, Nicholas R.		Initial version
            
        
            Script tested on the following Powershell Versions
                1.0   2.0   3.0   4.0   5.0   5.1 
            ----- ----- ----- ----- ----- -----
                X    X      X     X     ✓    ✓

            Credits:
                (1) Script Template: https://gist.github.com/9to5IT/9620683

            To Do List:
                (1) Get Powershell Path based on version (stock powershell, core, etc.)
        #>
        Param (
            [Parameter(Mandatory=$True)]
            [ValidateNotNullOrEmpty()]
            [String]$Path,

            [Parameter(Mandatory=$False)]
            [ValidateSet("REG_BINARY","REG_DWORD","REG_EXPAND_SZ","REG_MULTI_SZ","REG_SZ","REG_LINK","REG_QWORD","REG_NONE")]
            [String]$DataType,

            [Parameter(Mandatory=$False)]
            [ValidateNotNullOrEmpty()]
            [String]$Name,

            [Parameter(Mandatory=$False)]
            [ValidateNotNullOrEmpty()]
            [String]$Value,

            [Parameter(Mandatory=$True)]
            [ValidateNotNullOrEmpty()]
            [ValidateSet("HKEY_USERS","HKEY_CLASSES_ROOT","HKEY_CURRENT_CONFIG","HKEY_CURRENT_USER","HKEY_LOCAL_MACHINE")]
            [String]$RegistryHive,
            [Bool]$CreateKey = $True,
            [ValidateSet(0,1,2)]
            [Int]$Confim = 2,
            [Bool]$FixDataType = $False
        )

        #This is custom entry to save several hundred lines of code throughout the script. If this function is used elsewhere it should be removed.
        IF ([String]::IsNullOrWhiteSpace($Script:DefaultUserPath) -eq $False -AND $RegistryHive -eq "HKEY_CURRENT_USER") {
            IF ($Script:TargetUser -eq "Both") {
                Set-RegistryKey -RegistryHive HKEY_LOCAL_MACHINE -Path "$DefaultUserPath\$Path" -DataType $DataType  -Name $Name -Value $Value -CreateKey $CreateKey -Confim $Confim -FixDataType $FixDataType
            } ElseIF ($Script:TargetUser -eq "DefaultUser") {
                Set-Variable -Name RegistryHive -Value "HKEY_LOCAL_MACHINE" -Force -ErrorAction Stop -Verbose:$Verbose
                Set-Variable -Name Path -Value "$DefaultUserPath\$Path" -Force -ErrorAction Stop -Verbose:$Verbose
            }
        }

        IF ($PSBoundParameters.ContainsKey('Verbose')) {
            Set-Variable -Name Verbose -Value $True
        } Else {
            Set-Variable -Name Verbose -Value ([Bool]$Script:Verbose)
        }

        IF ($PSBoundParameters.ContainsKey('Confirm')) {
            Set-Variable -Name Confirm -Value $Confirm
        } Else {
            Set-Variable -Name Confirm -Value ([Bool]$Script:Confirm)
        }

        Switch ($Confirm) {
            0 {$ConfimEnv = $True;  $ConfirmChg = $True}
            1 {$ConfimEnv = $False; $ConfirmChg = $True}
            2 {$ConfimEnv = $False; $ConfirmChg = $False}
        }

        

        #Debug info to help with troubleshooting. Provides detailed variable information to better understand how the function was called.
        Write-nLog -Type Debug -Message "`$Path: $Path"
        Write-nLog -Type Debug -Message "`$DataType: $DataType"
        Write-nLog -Type Debug -Message "`$Name: $Name"
        Write-nLog -Type Debug -Message "`$Value: $Value"
        Write-nLog -Type Debug -Message "`$RegistryHive: $RegistryHive"
        Write-nLog -Type Debug -Message "`$CreateKey: $CreateKey"
        Write-nLog -Type Debug -Message "`$FixDataType: $FixDataType"

        #Create variables needed throughout function.
        New-Variable -Name NewKey             -Value $False -Force -ErrorAction Stop -Verbose:$Verbose
        New-Variable -Name SetItemProperty    -Value $False -Force -ErrorAction Stop -Verbose:$Verbose
        New-Variable -Name UpdateItemProperty -Value $True  -Force -ErrorAction Stop -Verbose:$Verbose
        New-Variable -Name HiveTypeDB                       -Force -ErrorAction Stop -Verbose:$Verbose -Value @{
            'HKEY_USERS'          = [Microsoft.Win32.RegistryHive]::Users
            'HKEY_CLASSES_ROOT'   = [Microsoft.Win32.RegistryHive]::ClassesRoot
            'HKEY_CURRENT_CONFIG' = [Microsoft.Win32.RegistryHive]::CurrentConfig
            'HKEY_CURRENT_USER'   = [Microsoft.Win32.RegistryHive]::CurrentUser
            'HKEY_LOCAL_MACHINE'  = [Microsoft.Win32.RegistryHive]::LocalMachine
        }
        New-Variable -Name DataTypeDB                       -Force -ErrorAction Stop -Verbose:$Verbose -Value @{
            'REG_BINARY'    = [Microsoft.Win32.RegistryValueKind]::Binary
            'REG_DWORD'     = [Microsoft.Win32.RegistryValueKind]::DWord
            'REG_EXPAND_SZ' = [Microsoft.Win32.RegistryValueKind]::ExpandString
            'REG_MULTI_SZ'  = [Microsoft.Win32.RegistryValueKind]::MultiString
            'REG_SZ'        = [Microsoft.Win32.RegistryValueKind]::String
            'REG_QWORD'     = [Microsoft.Win32.RegistryValueKind]::QWord
            'REG_NONE'      = [Microsoft.Win32.RegistryValueKind]::None
        }

        #Trim the path if needed.
        Set-Variable -Name Path -Value ($Path.Trim("\")) -Force -ErrorAction Stop -Verbose:$Verbose


        #Test if the path exists
        If (Test-Path -Path Registry::$RegistryHive\$Path -PathType Container -Verbose:$Verbose) {
            Write-nLog -Type Debug -Message "Registry key does exist."
            New-Variable -Name RegistryKey    -Value ([Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($HiveTypeDB[$RegistryHive],$env:COMPUTERNAME)) -Force -Verbose:$Verbose
            New-Variable -Name RegistrySubKey -Value ($RegistryKey.OpenSubKey($Path)) -Force -Verbose:$Verbose
        } Else { #endIf: If the path doesn't exist, throw an error.
            Write-nLog -Type Info -Message "Registry Key does not exist."
            If ($CreateKey) {
                Write-nLog -Type Debug -Message "Attempting to create registry key."
                Try {
                    New-Variable -Name RegistryKey    -Value ([Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($HiveTypeDB[$RegistryHive],$env:COMPUTERNAME)) -Force -Verbose:$Verbose
                    New-Variable -Name RegistrySubKey -Value ($RegistryKey.CreateSubKey($Path)) -Force -Verbose:$Verbose
                    Write-nLog -Type Info -Message "Successfully created registry key."
                    Set-Variable -Name NewKey   -Value $True -Force -Verbose:$Verbose
                } Catch {
                    Write-nLog -Type Error -Message "Unable to create registry key."
                    $Global:SSCError = $Error[0]
                    $RegistrySubKey.Close()
                    $RegistryKey.close()
                    return
                }
            } Else { #ElseIf: $CreateKey
                
            } #EndIf: $CreateKey
        }
        
        If (Test-Path Variable:\RegistrySubKey) {
            IF ($NewKey -eq $False) {
                Write-nLog -Type Debug -Message "Checking to see if registry property exists."
                IF ($RegistrySubKey.GetValueNames().Contains($Name) -EQ $True) {
                    $RegistrySubKey.SetValue($Name,$Value,$DataTypeDB[$DataType])
                    Set-Variable -Name SetItemProperty -Value $True -Force -ErrorAction Stop -Verbose:$Verbose
                    IF ($RegistrySubKey.GetValueKind("$Name") -ne $DataTypeDB[$DataType]) {
                        Write-nLog -Type Info -Message "Registry property type is '$($RegistryKey.GetValueKind($Name))' but expected '$($DataTypeDB[$DataType])."
                        If ($FixDataType) {
                            Write-nLog -Type Debug -Message "Attempting to remove registry key property to change ItemType."
                            Try {
                                $RegistrySubKey.DeleteValue("$Name")
                                Write-nLog -Type Info -Message "Successfully removed 'Registry::$RegistryHive\$Path\$Name'."
                                Set-Variable -Name SetItemProperty -Value $False -Force -ErrorAction Stop -Verbose:$Verbose
                            } Catch {
                                Write-nLog -Type Error -Message "Failed to remove 'Registry::$RegistryHive\$Path\$Name'."
                                $Global:SSCError = $Error[0]
                                $RegistrySubKey.Close()
                                $RegistryKey.close()
                                return
                            }
                        } Else { #ElseIf: $FixDataType
                            Write-nLog -Type Warning -Message "Registry property type is '$($RegistryKey.GetValueKind("$Name"))' but expected '$($DataTypeDB[$DataType])."
                        } #EndIf: $FixDataType
                    } Else {
                        #Check to see if the current registry value is the same as the desired value
                        IF ($RegistrySubKey.GetValue($Name) -eq $Value) {
                            Set-Variable -Name UpdateItemProperty -Value $False -Force -ErrorAction Stop -Verbose:$Verbose
                        }
                    }
                } #EndIf
            }

            #If registry key already desired value, no changes needed.
            if ($UpdateItemProperty) {
                IF ($SetItemProperty) {
                    Write-nLog -Type Debug -Message "Attempting to set item property value."
                    Try {
                        $RegistrySubKey.SetValue($Name,$Value)
                        Write-nLog -Type Info -Message "Successfully set '$RegistryHive\$Path\$Value' to '$Value'."
                    } Catch {
                        Write-nLog -Type Error -Message "Failed to set '$RegistryHive\$Path\$Value' to '$Value'."
                        $Global:SSCError = $Error[0]
                        $RegistrySubKey.Close()
                        $RegistryKey.close()
                        return
                    }
                } Else {#ElseIf: SetItemProprty
                    Write-nLog -Type Debug -Message "Attempting to create item property and set value."
                    Try {
                        $RegistrySubKey.SetValue($Name,$Value,$DataTypeDB[$DataType])
                        Write-nLog -Type Info -Message "Successfully added '$RegistryHive\$Path\$Value' property and set value to '$Value'."
                    } Catch [System.UnauthorizedAccessException] {
                        Write-nLog -Type Error -Message "Access denied when attempting to set '$RegistryHive\$Path\$Value' to '$Value'."
                    } Catch {
                        Write-nLog -Type Error -Message "Failed to set '$RegistryHive\$Path\$Value' to '$Value'."
                        $Global:SSCError = $Error[0]
                        $RegistrySubKey.Close()
                        $RegistryKey.close()
                        return
                    }
                }#EndIf: $SetItemProperty
            } Else {#ElseIf: $UpdateItemProperty
                Write-nLog -Type Info -Message "Registry key propety already at desired value and key type, no changes needed."
            }#EndIf: $UpdateItemProperty
        }

        $RegistrySubKey.Close()
        $RegistryKey.close()

    }
    Function local:Remove-RegistryKey {
        <#
            .SYNOPSIS
                Used to set remove key value.

            .DESCRIPTION
                Robust function used to remove a registry value with error handling and logging.
            
            .PARAMETER RegistryHive
                [String] Used to determine the default state of the ribbon in explorer when tablet mode is off.
                    HKEY_USERS            = 
                    HKEY_CLASSES_ROOT     = 
                    HKEY_CURRENT_CONFIG   = 
                    HKEY_CURRENT_USER     = 
                    HKEY_LOCAL_MACHINE    =

            .PARAMETER Path
                [String] Path of the registry key that the value will be removed.
            
            .PARAMETER Name
                [String] Name of the key property.

            .PARAMETER Confirm
                [Int] Determine what type of changes should be prompted before executing.
                    0 - Confirm both environment and object changes.
                    1 - Confirm only object changes.
                    2 - Confirm nothing! (Default)
                    Object Changes are changes that are permanent such as file modifications, registry changes, etc.
                    Environment changes are changes that can normally be restored via restart, such as opening/closing applications.

            .INPUTS
                None

            .OUTPUTS
                None

            .NOTES
            VERSION     DATE			NAME						DESCRIPTION
	        ___________________________________________________________________________________________________________
	        1.0         01 April 2021	Warilia, Nicholas R.		Initial version
            
        
            Script tested on the following Powershell Versions
                1.0   2.0   3.0   4.0   5.0   5.1 
            ----- ----- ----- ----- ----- -----
                X    X      X     X     ✓    ✓

            Credits:
                (1) Script Template: https://gist.github.com/9to5IT/9620683

            To Do List:
                (1) Get Powershell Path based on version (stock powershell, core, etc.)
        #>
        Param (
            [Parameter(Mandatory=$True)]
            [ValidateNotNullOrEmpty()]
            [String]$Path,

            [Parameter(Mandatory=$False)]
            [ValidateNotNullOrEmpty()]
            [String]$Name,

            [Parameter(Mandatory=$True)]
            [ValidateNotNullOrEmpty()]
            [ValidateSet("HKEY_USERS","HKEY_CLASSES_ROOT","HKEY_CURRENT_CONFIG","HKEY_CURRENT_USER","HKEY_LOCAL_MACHINE")]
            [String]$RegistryHive,

            [ValidateSet(0,1,2)]
            [Int]$Confim = 2
        )

        #This is custom entry to save several hundred lines of code throughout the script. If this function is used elsewhere it should be removed.
        IF ([String]::IsNullOrWhiteSpace($Script:DefaultUserPath) -eq $False -AND $RegistryHive -eq "HKEY_CURRENT_USER") {
            IF ($Script:TargetUser -eq "Both") {
                Remove-RegistryKey -RegistryHive HKEY_LOCAL_MACHINE -Path "$Script:DefaultUserPath\$Path" -Name $Name -Confim $Confirm
            } ElseIF ($Script:TargetUser -eq "DefaultUser") {
                Set-Variable -Name RegistryHive -Value "HKEY_LOCAL_MACHINE" -Force -ErrorAction Stop -Verbose:$Verbose
                Set-Variable -Name Path -Value "$DefaultUserPath\$Path" -Force -ErrorAction Stop -Verbose:$Verbose
            }
        }

        IF ($PSBoundParameters.ContainsKey('Verbose')) {
            Set-Variable -Name Verbose -Value $True
        } Else {
            Set-Variable -Name Verbose -Value ([Bool]$Script:Verbose)
        }

        IF ($PSBoundParameters.ContainsKey('Confirm')) {
            Set-Variable -Name Confirm -Value $Confirm
        } Else {
            Set-Variable -Name Confirm -Value ([Bool]$Script:Confirm)
        }

        Switch ($Confirm) {
            0 {$ConfimEnv = $True;  $ConfirmChg = $True}
            1 {$ConfimEnv = $False; $ConfirmChg = $True}
            2 {$ConfimEnv = $False; $ConfirmChg = $False}
        }

        #Debug info to help with troubleshooting. Provides detailed variable information to better understand how the function was called.
        Write-nLog -Type Debug -Message "`$Path: $Path"
        Write-nLog -Type Debug -Message "`$Name: $Name"
        Write-nLog -Type Debug -Message "`$RegistryHive: $RegistryHive"

        #Create variables needed throughout function.
        New-Variable -Name NewKey             -Value $False -Force -ErrorAction Stop -Verbose:$Verbose

        #Trim the path if needed.
        Set-Variable -Name Path -Value ($Path.Trim("\")) -Force -ErrorAction Stop -Verbose:$Verbose

        #Test if the path exists
        If (Test-Path -Path "Registry::$RegistryHive\$Path" -PathType Container -Verbose:$Verbose) {
            Write-nLog -Type Debug -Message "Key does exist."
            New-Variable -Name RegistryKey    -Value ([Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($HiveTypeDB[$RegistryHive],$env:COMPUTERNAME)) -Force -Verbose:$Verbose
            New-Variable -Name RegistrySubKey -Value ($RegistryKey.CreateSubKey($Path)) -Force -Verbose:$Verbose
            IF ($RegistrySubKey.GetValueNames().Contains($Name) -EQ $True) {
                Write-nLog -Type Debug -Message "Property '$Name' does exist."
                Try {
                    $SubKey.DeleteValue($Name)
                    Write-nLog -Type Info -Message "Successfully deleted 'Registry::$RegistryHive\$Path\$name'."
                } Catch {
                    Write-nLog -Type Error -Message "Unable to delete 'Registry::$RegistryHive\$Path\$name'."
                    $Global:SSCError = $Error[0]
                    $RegistrySubKey.Close()
                    $RegistryKey.close()
                    return
                }
            } Else { #ElseIf: ($RegistryKey.Property.contains("$Name") -EQ $True)
                Write-nLog -Type Debug -Message "Property '$Name' does not exist."
            } #EndIf: ($RegistryKey.Property.contains("$Name") -EQ $True)
        } Else { #endIf
            Write-nLog -Type Debug -Message "Registry key doesn't exist, no further action needed."
        }

        $RegistrySubKey.Close()
        $RegistryKey.close()
    }
    
    #----------------------------------------------- [Initializations & Prerequisites] -----------------------------------------------

    #Determine the Log Output Level
    Switch ($LogLevel) {
        "Verbose" {$LogLevelInt = 1; $DebugPreference = 'Continue'        ; $VerbosePreference = 'Continue'        ; $InformationPreference = 'Continue'        ; $WarningPreference = 'Continue'        ; $ErrorPreference = 'Continue'        }
        "Debug"   {$LogLevelInt = 1; $DebugPreference = 'Continue'        ; $VerbosePreference = 'SilentlyContinue'; $InformationPreference = 'Continue'        ; $WarningPreference = 'Continue'        ; $ErrorPreference = 'Continue'        }
        "Info"    {$LogLevelInt = 2; $DebugPreference = 'SilentlyContinue'; $VerbosePreference = 'SilentlyContinue'; $InformationPreference = 'Continue'        ; $WarningPreference = 'Continue'        ; $ErrorPreference = 'Continue'        }
        "Warn"    {$LogLevelInt = 3; $DebugPreference = 'SilentlyContinue'; $VerbosePreference = 'SilentlyContinue'; $InformationPreference = 'SilentlyContinue'; $WarningPreference = 'Continue'        ; $ErrorPreference = 'Continue'        }
        "Error"   {$LogLevelInt = 4; $DebugPreference = 'SilentlyContinue'; $VerbosePreference = 'SilentlyContinue'; $InformationPreference = 'SilentlyContinue'; $WarningPreference = 'SilentlyContinue'; $ErrorPreference = 'Continue'        }
        "Off"     {$LogLevelInt = 0; $DebugPreference = 'SilentlyContinue'; $VerbosePreference = 'SilentlyContinue'; $InformationPreference = 'SilentlyContinue'; $WarningPreference = 'SilentlyContinue'; $ErrorPreference = 'SilentlyContinue'}
    }

    #Converts Verbose Prefernce to bool so it can be used in "-Verbose:" arguments.
    [Bool]$Verbose = ($VerbosePreference -eq 'Continue')

    #Set Set Debug Level
    Switch ($Debugger) {
        0 { $ConfimEnv = $True ;  $ConfirmChg = $True;  $Verbose = $True; $InformationPreference = 'Continue'; $ErrorActionPreference = 'Stop'; $VerbosePreference = 'Continue'; $DebugPreference = 'Continue'; Set-StrictMode -Version Latest; Set-PsDebug -Trace 1}
        1 { $ConfimEnv = $True ;  $ConfirmChg = $True;  $Verbose = $True; $InformationPreference = 'Continue'; $ErrorActionPreference = 'Stop'; $VerbosePreference = 'Continue'}
        2 { $ConfimEnv = $False ; $ConfirmChg = $False; $Verbose = $True; $InformationPreference = 'Continue'}
    }

    Switch ($Confirm) {
        0 {$ConfimEnv = $True;  $ConfirmChg = $True}
        1 {$ConfimEnv = $False; $ConfirmChg = $True}
        2 {$ConfimEnv = $False; $ConfirmChg = $False}
    }

    #Variable used to store certain sometimes useful script related information.
    New-Variable -Name ScriptEnv -Force -ErrorAction Stop -Verbose:$Verbose -value @{
        RunMethod      = [String]::Empty
        Interactive    = [Bool]$([Environment]::GetCommandLineArgs().Contains('-NonInteractive') -or ([Environment]::UserInteractive -EQ $False))
        IsAdmin        = [Bool]$((New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
        Parameters     = New-Object -TypeName "System.Text.StringBuilder"
        ScriptDir      = [String]::Empty
        ScriptFullName = [String]::Empty
        Powershellpath = "$($env:windir)\System32\WindowsPowerShell\v1.0\powershell.exe"
    }
    
    #Create a proper parameter string.
    ForEach ($Parameter in $Script:PSBoundParameters.GetEnumerator()) {
        [void]$ScriptEnv.Parameters.Append(" -$($Parameter.key): ""$($Parameter.Value)""")
    }

    #Determine The Environment The Script is Running in.
    IF (Test-Path Variable:PSise) {
        #Running as PSISE
        [String]$ScriptEnv.RunMethod = 'ISE'
        [System.IO.DirectoryInfo]$ScriptEnv.ScriptDir = Split-Path $psISE.CurrentFile.FullPath
        [System.IO.DirectoryInfo]$ScriptEnv.ScriptFullName = $psISE.CurrentFile.FullPath
    } ElseIF (Test-Path -Path Variable:pseditor) {
        #Running as VSCode
        [String]$ScriptEnv.RunMethod = 'VSCode'
        [System.IO.DirectoryInfo]$ScriptEnv.ScriptDir = Split-Path $pseditor.GetEditorContext().CurrentFile.Path
        [System.IO.DirectoryInfo]$ScriptEnv.ScriptFullName = $pseditor.GetEditorContext().CurrentFile.Path
    } Else {
        #Running as AzureDevOps or Powershell
        [String]$ScriptEnv.RunMethod = 'ADPS'
        IF ($Host.Version.Major -GE 3) {
            [System.IO.DirectoryInfo]$ScriptEnv.ScriptDir = $PSScriptRoot
            [System.IO.DirectoryInfo]$ScriptEnv.ScriptFullName = $PSCommandPath
        } Else {
            [System.IO.DirectoryInfo]$ScriptEnv.ScriptDir = split-path -parent $MyInvocation.MyCommand.Definition
            [System.IO.DirectoryInfo]$ScriptEnv.ScriptFullName = $MyInvocation.MyCommand.Definition
        }
    }
    
    #Check if administrator
    IF ($ScriptConfig.RequreAdmin -eq $True) {
        IF ($ScriptEnv.IsAdmin -eq $False) {
            Write-Warning -Message 'Warning: Script not running as administrator, relaunching as administrator.'
            IF ($ScriptEnv.RunMethod -eq 'ISE') {
                IF ($psISE.CurrentFile.IsUntitled-eq $True) {
                    Write-Error -Message 'Unable to elevate script, please save script before attempting to run.'
                    break
                } Else {
                    IF ($psISE.CurrentFile.IsSaved -eq $False) {
                        Write-Warning 'ISE Script unsaved, unexpected results may occur.'
                    }
                }
            }
            $Process = [System.Diagnostics.Process]::new()
            $Process.StartInfo = [System.Diagnostics.ProcessStartInfo]::new()
            $Process.StartInfo.Arguments = "-NoLogo -ExecutionPolicy Bypass -noprofile -command &{start-process '$($ScriptEnv.Powershellpath)' {$runthis} -verb runas}"
            $Process.StartInfo.FileName = $ScriptEnv.Powershellpath
            $Process.startinfo.WorkingDirectory = $ScriptEnv.ScriptDir
            $Process.StartInfo.UseShellExecute = $False
            $Process.StartInfo.CreateNoWindow  = $True
            $Process.StartInfo.RedirectStandardOutput = $True
            $Process.StartInfo.RedirectStandardError = $False
            $Process.StartInfo.RedirectStandardInput = $False
            $Process.StartInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Normal
            $Process.StartInfo.LoadUserProfile = $False
            [Void]$Process.Start()
            [Void]$Process.WaitForExit()
            [Void]$Process.Dispose()
            exit
        }
    }

    #--------------------------------------------------------- [Main Script] ---------------------------------------------------------
    Write-nLog -Initialize -Type Debug -Message "Starting nLog function." -SetLogDir $ScriptEnv.ScriptDir -SetLogLevel $LogLevelInt -SetWriteHost $False -SetWriteLog $True -SetTimeLocalization Local -SetLogFormat CMTrace
    
    #Mount Default User Profile
    If ($TargetUser-in @("DefaultUser","Both")) {
        New-Variable -Name Process -Value ([System.Diagnostics.Process]::new()) -Force -ErrorAction Stop -Verbose:$Verbose
        $Process.StartInfo = [System.Diagnostics.ProcessStartInfo]::new()
        $Process.StartInfo.Arguments = "LOAD HKLM\DEFAULT $Env:SystemDrive\Users\Default\NTUser.Dat"
        $Process.StartInfo.FileName = "$Env:WinDir\System32\Reg.exe"
        $Process.startinfo.WorkingDirectory = "$Env:WinDir\System32\"
        $Process.StartInfo.UseShellExecute = $False
        $Process.StartInfo.CreateNoWindow  = $True
        $Process.StartInfo.RedirectStandardOutput = $True
        $Process.StartInfo.RedirectStandardError = $False
        $Process.StartInfo.RedirectStandardInput = $False
        $Process.StartInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Normal
        $Process.StartInfo.LoadUserProfile = $False
        [Void]$Process.Start()
        [Void]$Process.WaitForExit()
        $Process.ExitCode
        [Void]$Process.Dispose()
        Remove-Variable -name Process -Force -ErrorAction Stop -Verbose:$Verbose
        New-Variable -Name DefaultUserPath -Value "DEFAULT" -Force -ErrorAction Stop -Verbose:$Verbose
    }

    #MinimizedStateTabletModeOn
    Set-RegistryKey -RegistryHive HKEY_CURRENT_USER -Path "SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Ribbon" -Name MinimizedStateTabletModeOn -DataType REG_DWORD -Value $MinimizedStateTabletModeOn

    #MinimizedStateTabletModeOff
    Set-RegistryKey -RegistryHive HKEY_CURRENT_USER -Path "SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Ribbon" -Name MinimizedStateTabletModeOff -DataType REG_DWORD -Value $MinimizedStateTabletModeOff

    #Windows Feedback Frequency
    Switch ($WindowsFeedbackFrequency) {
        "Automatically" {
            Remove-RegistryKey -RegistryHive HKEY_CURRENT_USER -Path "Software\Microsoft\Siuf\Rules" -Name PeriodInNanoSeconds
            Remove-RegistryKey -RegistryHive HKEY_CURRENT_USER -Path "Software\Microsoft\Siuf\Rules" -Name NumberOfSIUFInPeriod
        }
        "Never" {
            Set-RegistryKey -RegistryHive HKEY_CURRENT_USER -Path "Software\Microsoft\Siuf\Rules" -Name PeriodInNanoSeconds -Value 0 -DataType REG_DWORD
            Set-RegistryKey -RegistryHive HKEY_CURRENT_USER -Path "Software\Microsoft\Siuf\Rules" -Name NumberOfSIUFInPeriod -Value 0 -DataType REG_DWORD
        }
        "Always" {
            Set-RegistryKey -RegistryHive HKEY_CURRENT_USER -Path "Software\Microsoft\Siuf\Rules" -Name 100000000 -Value 0 -DataType REG_DWORD
            Remove-RegistryKey -RegistryHive HKEY_CURRENT_USER -Path "Software\Microsoft\Siuf\Rules" -Name NumberOfSIUFInPeriod
        }
        "Daily" {
            Set-RegistryKey -RegistryHive HKEY_CURRENT_USER -Path "Software\Microsoft\Siuf\Rules" -Name PeriodInNanoSeconds -Value 864000000000 -DataType REG_DWORD
            Set-RegistryKey -RegistryHive HKEY_CURRENT_USER -Path "Software\Microsoft\Siuf\Rules" -Name NumberOfSIUFInPeriod -Value 1 -DataType REG_DWORD
        }
        "Weekly" {
            Set-RegistryKey -RegistryHive HKEY_CURRENT_USER -Path "Software\Microsoft\Siuf\Rules" -Name PeriodInNanoSeconds -Value 6048000000000 -DataType REG_DWORD
            Set-RegistryKey -RegistryHive HKEY_CURRENT_USER -Path "Software\Microsoft\Siuf\Rules" -Name NumberOfSIUFInPeriod -Value 1 -DataType REG_DWORD
        }
    }

    #DoNotShowFeedbackNotifications
    Set-RegistryKey -RegistryHive HKEY_LOCAL_MACHINE -Path "SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name DoNotShowFeedbackNotifications -Value $DoNotShowFeedbackNotifications -DataType REG_DWORD
    
    #LetAppsActivateWithVoiceAllUsers
    Set-RegistryKey -RegistryHive HKEY_LOCAL_MACHINE -Path "SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Value $LetAppsActivateWithVoiceAllUsers -DataType REG_DWORD -Name LetAppsActivateWithVoice

    #LetAppsActivateWithVoiceAboveLockAllUsers
    Set-RegistryKey -RegistryHive HKEY_LOCAL_MACHINE -Path "SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Value $LetAppsActivateWithVoiceAboveLockAllUsers -DataType REG_DWORD -Name LetAppsActivateWithVoiceAboveLock

    #AllowCrossDeviceClipboard
    IF ($AllowCrossDeviceClipboard -eq 1) {
        Remove-RegistryKey -RegistryHive HKEY_LOCAL_MACHINE -Path "SOFTWARE\Policies\Microsoft\Windows\System" -Name AllowCrossDeviceClipboard
    } Else {
        Set-RegistryKey -RegistryHive HKEY_LOCAL_MACHINE -Path "SOFTWARE\Policies\Microsoft\Windows\System" -Value $AllowCrossDeviceClipboard -DataType REG_DWORD -Name AllowCrossDeviceClipboard
    }

    #OnlineSpeechRecognition
    IF ($OnlineSpeechRecognition -eq 1) {
        Remove-RegistryKey -RegistryHive HKEY_LOCAL_MACHINE -Path "SOFTWARE\Policies\Microsoft\InputPersonalization" -Name AllowInputPersonalization
    } Else {
        Set-RegistryKey -RegistryHive HKEY_LOCAL_MACHINE -Path "SOFTWARE\Policies\Microsoft\InputPersonalization" -Value $OnlineSpeechRecognition -DataType REG_DWORD -Name AllowInputPersonalization
    }

    #Flush out any unwritten/finalized registry edits so UserNT.dat can be safely unmounted.
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()

    #Dismount Default User Profile
    If ($TargetUser-in @("DefaultUser","Both")) {
        New-Variable -Name Unloaded -Value $False -Force -ErrorAction Stop -Verbose:$Verbose
        New-Variable -Name Attempts -Value ([Int]0) -Force -ErrorAction Stop -Verbose:$Verbose
        While ($Unloaded -eq $False -AND $Attempts -lt 5) {
            New-Variable -Name Process -Value ([System.Diagnostics.Process]::new()) -Force -ErrorAction Stop -Verbose:$Verbose
            $Process.StartInfo = [System.Diagnostics.ProcessStartInfo]::new()
            $Process.StartInfo.Arguments = "UNLOAD HKLM\DEFAULT"
            $Process.StartInfo.FileName = "$Env:WinDir\System32\Reg.exe"
            $Process.startinfo.WorkingDirectory = "$Env:WinDir\System32\"
            $Process.StartInfo.UseShellExecute = $False
            $Process.StartInfo.CreateNoWindow  = $True
            $Process.StartInfo.RedirectStandardOutput = $True
            $Process.StartInfo.RedirectStandardError = $False
            $Process.StartInfo.RedirectStandardInput = $False
            $Process.StartInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Normal
            $Process.StartInfo.LoadUserProfile = $False
            [Void]$Process.Start()
            [Void]$Process.WaitForExit()
            If ($Process.ExitCode -eq 0) {
                Set-Variable -Name Unloaded -Value $True -Force -ErrorAction Stop -Verbose:$Verbose
            }
            [Void]$Process.Dispose()
            Remove-Variable -name Process -Force -ErrorAction Stop -Verbose:$Verbose
        }
    }

    #LetAppsActivateWithVoiceAboveLockAllUsers
    Write-nLog -Close -Type Debug -Message "Closing nLog"
    #-------------------------------------------------------- [End of Script] --------------------------------------------------------
    Remove-Variable -Name @("ScriptConfig","ScriptEnv") -ErrorAction SilentlyContinue -Force -Verbose:$Verbose
}

Start-SystemCustomizer



<#------------------------------------------------------ [Notes & Misc Code] ------------------------------------------------------


#>
