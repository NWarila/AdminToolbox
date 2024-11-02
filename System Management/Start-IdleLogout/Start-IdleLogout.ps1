Param (
    [Parameter(Mandatory=$True,Position=0)]
    [ValidateSet('Start','Stop')]
    [String]$Function,
    [Int]$MaxStopAttempts = '5'
)
<#	
    .NOTES
    VERSION     DATE			NAME						DESCRIPTION
	___________________________________________________________________________________________________________
	1.0     	30 June 2020	Nick W.						Initial version

    Credits:
        (1) Script Template: https://gist.github.com/9to5IT/9620683
	
#>

IF ($Function -eq 'Start') {
    Try {
        Get-Process -Name LogonUI -ErrorAction Stop
    } Catch {
        Write-Debug -Message "Current user logged on, ending script."
        exit
    }

    [System.DateTime]$StartTime = [DateTime]::Now
    [System.DateTime]$CurrentTime = $StartTime

    IF (Test-Path -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services") {
	    $Key = Get-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
	    $KeyValue = $Key.GetValue("MaxDisconnectionTime", $Null)
	    IF ($KeyValue -ne $null) {
		    $IdleTime = New-TimeSpan -Seconds ($KeyValue/1000)
	    }
    }

    While ((New-TimeSpan -Start $StartTime -End ([DateTime]::now)) -lt $IdleTime) {
	    Start-Sleep -Seconds 30
    }

    $Process = [System.Diagnostics.Process]::new()
    $Process.StartInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $Process.StartInfo.Arguments = ""
    $Process.StartInfo.FileName = "$($env:windir)\System32\logoff.exe"
    $Process.StartInfo.UseShellExecute = $False
    $Process.StartInfo.CreateNoWindow = $True
    $Process.StartInfo.RedirectStandardOutput = $True
    $Process.StartInfo.RedirectStandardError = $False
    $Process.StartInfo.RedirectStandardInput = $False
    $Process.StartInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
    $Process.StartInfo.LoadUserProfile = $False
    [Void]$Process.Start()
    [Void]$Process.WaitForExit()
} ElseIF ($Function -eq "Stop") {
    [Int]$StopAttempts = '0'
    $TaskState = Get-ScheduledTask -TaskName "Start-IdleLogoff" |Where-Object {$_.Principal.userID -match $env:USERNAME} |Select-Object -ExpandProperty State
    While ($TaskState -eq 'Running' -AND $StopAttempts -le $MaxStopAttempts) {
        Get-ScheduledTask -TaskName "Start-IdleLogoff" |Where-Object {$_.Principal.userID -match $env:USERNAME} |Stop-ScheduledTask
        $TaskState = Get-ScheduledTask -TaskName "Start-IdleLogoff" |Where-Object {$_.Principal.userID -match $env:USERNAME} |Select-Object -ExpandProperty State
        $StopAttempts++
    }
}
