@ECHO OFF
:: System
AuditPol.exe /set /SubCategory:"Security System Extension" /success:enable
AuditPol.exe /set /SubCategory:"System Integrity" /success:enable /failure:enable
AuditPol.exe /set /SubCategory:"IPsec Driver" /success:enable /failure:enable
AuditPol.exe /set /SubCategory:"Other System Events" /success:enable /failure:enable
AuditPol.exe /set /SubCategory:"Security State Change" /success:enable

:: Logon/Logoff
AuditPol.exe /set /SubCategory:"Logon" /success:enable /failure:enable
AuditPol.exe /set /SubCategory:"Logoff" /success:enable
AuditPol.exe /set /SubCategory:"Account Lockout" /success:enable /failure:enable
AuditPol.exe /set /SubCategory:"Special Logon" /success:enable

:: Object Access
AuditPol.exe /set /SubCategory:"Other Object Access Events" /success:enable /failure:enable

:: Privilege Use
AuditPol.exe /set /SubCategory:"Sensitive Privilege Use" /success:enable /failure:enable

:: Detailed Tracking
AuditPol.exe /set /SubCategory:"Process Creation" /success:enable

:: Policy Change
AuditPol.exe /set /SubCategory:"Audit Policy Change" /success:enable /failure:enable
AuditPol.exe /set /SubCategory:"Authentication Policy Change" /success:enable
AuditPol.exe /set /SubCategory:"Authorization Policy Change" /success:enable

:: Account Management
AuditPol.exe /set /SubCategory:"Security Group Management" /success:enable
AuditPol.exe /set /SubCategory:"Other Account Management Events" /success:enable
AuditPol.exe /set /SubCategory:"User Account Management" /success:enable /failure:enable

:: DS Access
AuditPol.exe /set /SubCategory:"Directory Service Access" /success:enable /failure:enable
AuditPol.exe /set /SubCategory:"Directory Service Changes" /success:enable /failure:enable

:: Account Logon
AuditPol.exe /set /SubCategory:"Credential Validation" /success:enable /failure:enable
