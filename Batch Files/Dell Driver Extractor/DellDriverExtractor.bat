@ECHO OFF
Setlocal EnableDelayedExpansion

::===============================================================
:: Auto-Extract Driver Installation Files. (v1)
::===============================================================
::      Drop this batch file into a directory with dell driver 
:: driver installation files (post 2018) and it will attempt to
:: export all drivers to a folder in the same directory with the
:: same name as the driver file.
::===============================================================

:: >> %Temp%\ExtractFiles.log 2>&1 

CLS
ECHO. Pushing to Script Directory. (%~dp0)
PUSHD "%~dp0"

ECHO. Starting Installation.
FOR /F "TOKENS=*" %%A IN ('DIR /B "%~dp0\*.exe"') do (
	start /W /B "" /D "%~dp0" "%%~nA" /e="%~dp0%%~nA" /s >> %Temp%\ExtractFiles.log 2>&1 
)

ECHO. Exiting PUSHD directory.
POPD

start /B "" /D "%windir%\system32\" notepad.exe %Temp%\ExtractFiles.log

ECHO/ Script Complete!
pause
