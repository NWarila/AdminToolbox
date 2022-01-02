@ECHO OFF
::Setlocal EnableDelayedExpansion

::Push to current directory. >> %Temp%\%ComputerName%.log 2>&1 
CLS
ECHO. Pushing to Script Directory. (%~dp0)
PUSHD "%~dp0"

ECHO. Starting Installation.
for /r "%~dp0" %%A in (*.cab) do (
	mkdir "%Temp%\%%~nA" >> %Temp%\%ComputerName%.log 2>&1 
	start /W /B "" /D "%windir%\system32\" Expand.exe "%%~fA" "%Temp%\%%~nA" /f:* >> %Temp%\%ComputerName%.log 2>&1 
	start /W /B "" /D "%windir%\system32\" pnputil.exe /add-driver "%Temp%\%%~nA\*.inf" /subdirs /install >> %Temp%\%ComputerName%.log 2>&1 
	DEL /F /Q /S "%Temp%\%%~nA" >> %Temp%\%ComputerName%.log 2>&1 
	RMDIR /Q /S "%Temp%\%%~nA" >> %Temp%\%ComputerName%.log 2>&1 
)
ECHO. Installation Complete!

ECHO. Exiting PUSHD directory.
POPD

start /B "" /D "%windir%\system32\" notepad.exe %Temp%\%ComputerName%.log

ECHO/ Script Complete!
pause
