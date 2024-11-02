param(
    [int]$DaysToKeep=1,
    [Bool]$Logging=$True,
    [Switch]$WriteHost=$False,
    [String]$LogFile="$Env:SystemDrive\Log.txt"
)
$Script = @{}
$Script.ClearedSize = 0
[int]$Script.ClearedFiles = 0
$Script.Time = [DateTime]::Now
$Script.DaysToKeep = ($Script.Time).AddDays(-$DaysToKeep)
$Script.FileTypes = ".log",".blg",".etl",".xml"
$Script.LogDirs = @(
    "$env:ExchangeInstallPath`TransportRoles\Logs\Hub\"
    "$env:ExchangeInstallPath`Logging\"
    "$env:ExchangeInstallPath`Bin\Search\Ceres\Diagnostics\Logs"
)

ForEach ($LogDir in $Script.LogDirs) {
    Try {
        Get-ChildItem -literalPath $LogDir -ErrorAction stop -Recurse | Where-Object { !$_.PSIsContainer -AND $Script.FileTypes -contains $_.Extension} |ForEach-Object {
            IF ($_.lastWriteTime -le $Script.DaysToKeep) {
                $CurrentFile = $_.FullName
                Write-Host "Deleting: $CurrentFile"
                Try {
                    Remove-Item -Path $CurrentFile -ErrorAction Stop -force
                    $Script.ClearedFiles += 1
                    $Script.ClearedSize += $_.Length
                } Catch {
                    switch($Error[0].Exception) {
                        {"*Cannot remove item * The process cannot access the file*"} {$ErrorOutput = "Remove-Item (Access denied): $CurrentFile"}
                        {"The process cannot access the file * because it is being used by another process."} {$ErrorOutput = "Remove-Item (File In Use): $CurrentFile"}
                        default {write-host $ErrorOutput -ForegroundColor Red -BackgroundColor Black}
                    }
                    write-host $Error[0].Exception -ForegroundColor Red -BackgroundColor Black
                    Out-File -LiteralPath $LogFile -Append -NoClobber -encoding ascii -InputObject "$(Get-Date -Format g) | $ErrorOutput"
                }
            } Else {
                Write-Host "Skipping: $($_.FullName)"
            }
        }
    } Catch {
        switch($Error[0].Exception) {
            Default {$ErrorOutput = $Error[0].Exception}
        }
        If ($Logging) {
            Out-File -LiteralPath $LogFile -Append -NoClobber -encoding ascii -InputObject "$(Get-Date -Format g) | $ErrorOutput"
        }
        write-host $ErrorOutput -ForegroundColor Red -BackgroundColor Black
        continue
    }
}

Write-Host "$(Get-Date -Format g) | $($Script.ClearedFiles) Files Removed | $([math]::Round($Script.ClearedSize/1MB))MB Regained."
Out-File -LiteralPath $LogFile -Append -NoClobber -encoding ascii -InputObject "$(Get-Date -Format g) | $($Script.ClearedFiles) Files Removed | $([math]::Round($Script.ClearedSize/1MB))MB Regained."



<#
Set-TransportService $env:COMPUTERNAME -ConnectivityLogPath "E:\Connectivity"
Set-TransportService $env:COMPUTERNAME -MessageTrackingLogPath "E:\TransportRoles\Logs\MessageTracking"
Set-TransportService $env:COMPUTERNAME -IrmLogPath "E:\Logging\IRMLogs"
Set-TransportService $env:COMPUTERNAME -ActiveUserStatisticsLogPath "E:\ActiveUsersStats"
Set-TransportService $env:COMPUTERNAME -ServerStatisticsLogPath "E:\TransportRoles\Logs\Hub\ServerStats"
Set-TransportService $env:COMPUTERNAME -PickupDirectoryPath "E:\TransportRoles\Pickup"
Set-TransportService $env:COMPUTERNAME -PipelineTracingPath "E:\TransportRoles\Logs\Hub\PipelineTracing"
Set-TransportService $env:COMPUTERNAME -ReceiveProtocolLogPath "E:\SMTPReceive"
Set-TransportService $env:COMPUTERNAME -ReplayDirectoryPath "E:\TransportRoles\Replay"
Set-TransportService $env:COMPUTERNAME -RoutingTableLogPath "E:\Routing Table Log"
Set-TransportService $env:COMPUTERNAME -SendProtocolLogPath "E:\smtpsend"
Set-TransportService $env:COMPUTERNAME -QueueLogPath "E:\QueueViewer"
Set-TransportService $env:COMPUTERNAME -WlmLogPath "E:\TransportRoles\Logs\WLM"
Set-TransportService $env:COMPUTERNAME -AgentLogPath "E:\TransportRoles\Logs\Hub\AgentLog"
Set-TransportService $env:COMPUTERNAME -TransportHttpLogPath "E:\TransportRoles\Logs\Hub\TransportHttp"
Set-TransportService $env:COMPUTERNAME -LatencyLogPath "E:\TransportRoles\Logs\Hub\LatencyLog"
Set-TransportService $env:COMPUTERNAME -GeneralLogPath "E:\TransportRoles\Logs\Hub\GeneralLog"
Set-TransportService $env:COMPUTERNAME -JournalLogPath "E:\TransportRoles\Logs\JournalLog"
#>
