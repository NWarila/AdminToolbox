# Update Me
[Array]$Programs = @(
    "$Env:ProgramFiles\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe"
    "${Env:ProgramFiles(x86)}\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe"
)
[Array]$ProgramDirs = @(
    "$Env:ProgramFiles\Adobe\Acrobat Reader DC\"
    "${Env:ProgramFiles(x86)}\Adobe\Acrobat Reader DC\"
)

<# Don't Edit Below this line
###############################################################################################################################
-= Dynamic Processes Termination Tool =-
Quick and Easy processes termination tool

VERSION     DATE			NAME						DESCRIPTION
___________________________________________________________________________________________________________
5.0         21 Aug 2020		Warila, Nicholas R.			Initial version

Credits:
    (1) Script Template: https://gist.github.com/9to5IT/9620683

Updates Available at:
    (1) Github: 
#>
New-Variable -Name Processes -Value (Get-Process |Select Id,Path) -Description "List of all running processes." -Force
New-Variable -Name Running1 -Value @{} -Description "List of all running applications that need to be killed." -Force
New-Variable -Name Running2 -Value @{} -Description "List of all running applications that need to be killed." -Force
New-Variable -Name ErrorCount -Value $([int]0) -Description "Total number of errors encoutered." -Force

IF (![string]::IsNullOrEmpty($ProgramDirs)) {
    $Running1 = $Processes.path | Select-String -Pattern $ProgramDirs -SimpleMatch |Select -Unique
}

IF (![string]::IsNullOrEmpty($Programs)) {
    $Running2 = $Processes.path | Select-String -Pattern $Programs -SimpleMatch |Select -Unique
}

ForEach ($Process in ($Running1,$Running2)) {
    IF (-NOT [String]::IsNullOrEmpty($Process)) {
        $Processes | Where {$_.path -eq $Process} |foreach {
            Try {
                Stop-Process -id $_.id -Force -ErrorAction Stop
                Write-Output -InputObject "[Info] Successfully stopped process: $(([System.IO.FileInfo]$_.Path).name)"
            } Catch {
                Write-Output -InputObject "[Error] Unable to stop process. $(([System.IO.FileInfo]$_.Path).name)"
                $ErrorCount++
            }
        }
    }
    Remove-Variable -Name Process -ErrorAction SilentlyContinue -Force
}

if ($ErrorCount -eq 0) {
    Remove-Variable -Name @("Processes","Running1","Running2","ProgramDirs","Programs","ErrorCount") -ErrorAction SilentlyContinue -Force
    Exit 0
} Else {
    Remove-Variable -Name @("Processes","Running1","Running2","ProgramDirs","Programs","ErrorCount") -ErrorAction SilentlyContinue -Force
    Exit 1
}
