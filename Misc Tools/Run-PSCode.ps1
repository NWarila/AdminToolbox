<# :# PowerShell comment protecting the Batch section
@echo off

:# Clear console to supress any errors.
cls

:# Disabling argument expansion avoids issues with ! in arguments.
SetLocal EnableExtensions DisableDelayedExpansion

:# Prepare the batch arguments, so that PowerShell parses them correctly
SET ARGS=%*
IF defined ARGS set ARGS=%ARGS:"=\"%
IF defined ARGS set ARGS=%ARGS:'=''%

:# Ensure path is utilizing a lettered drive path.
SET "FilePath=%~f0"
IF "%FilePath:~0,2%" == "\\" PUSHD "%~dp0"
SET "FilePath=%CD%\%~nx0"

:# Escape the file path for all possible invalid characters.
SET "FilePath=%FilePath:'=''%"
SET "FilePath=%FilePath:^=^^%"
SET "FilePath=%FilePath:[=`[%"
SET "FilePath=%FilePath:]=`]%"
SET "FilePath=%FilePath:&=^&%"

:# ============================================================================================================ #:
:# The ^ before the first " ensures that the Batch parser does not enter quoted mode there, but that it enters  #:
:# and exits quoted mode for every subsequent pair of ". This in turn protects the possible special chars & | < #:
:# > within quoted arguments. Then the \ before each pair of " ensures that PowerShell's C command line parser  #:
:# considers these pairs as part of the first and only argument following -c. Cherry on the cake, it's possible #:
:# to pass a " to PS by entering two "" in the bat args.                                                        #:
:# ============================================================================================================ #:
ECHO In BATCH; Entering PowerShell.
"%WinDir%\System32\WindowsPowerShell\v1.0\powershell.exe" -c ^
    ^"Invoke-Expression ('^& {' + (get-content -raw '%FilePath%') + '} %ARGS%')"
ECHO Exited PowerShell; Back in BATCH.


pause
POPD
exit /b

###############################################################################
End of the PS comment around the Batch section; Begin the PowerShell section #>

echo "In PowerShell"
$Args | % { "PowerShell Args[{0}] = '$_'" -f $i++ }
exit 0
