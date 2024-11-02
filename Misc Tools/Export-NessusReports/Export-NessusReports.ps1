<#
    .SYNOPSIS
        Automatically export 

    .DESCRIPTION
        Export nessus logs. 

    .PARAMETER <Parameter_Name>
        
    .INPUTS
        None

    .OUTPUTS
        None

    .NOTES
    VERSION     DATE			NAME						DESCRIPTION
	___________________________________________________________________________________________________________
	1.0         05 March 2020	Warilia, Nicholas R.		Initial version

    Credits:
        (1) Script Template: https://gist.github.com/9to5IT/9620683
        (2) Certificate Policy: https://gallery.technet.microsoft.com/site/search?f[0].Type=User&f[0].Value=paperclips
        (3) Certificate Policy: https://stackoverflow.com/questions/36456104/invoke-restmethod-ignore-self-signed-certs
#>

<#  
ScriptName: NessusPro_v7_Report_Exporter_Tool.ps1 
PSVersion:  5.1 
Purpose:    Powershell script that use REST methods to obtain report automation tasks. 
Created:    Sept 2018. 
Comments: 
Notes:      -Script must be run with ACL that has proxy access if external facing Nessus.io servers are targeted 
            -Ensure execution policy is set to unrestricted (Requires Administrative ACL) 
Author:     Paperclips. 
Email:      Pwd9000@hotmail.co.uk 
TechNet:    https://gallery.technet.microsoft.com/site/search?f[0].Type=User&f[0].Value=paperclips 
Github:     https://github.com/Pwd9000-ML 
#> 

[CmdletBinding()]
Param (
    [Parameter(ValueFromPipelineByPropertyName=$true,Position=0)]
    [String]$NessusServer = $env:COMPUTERNAME,

    [Parameter(ValueFromPipelineByPropertyName=$true,Position=1)]
    [Int]$Port = 8834,

    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$true,Position=2)]
    [String]$Username,

    [Parameter(ValueFromPipelineByPropertyName=$true,Position=3)]
    [String]$OutputDir = "C:\Nessus\$(([DateTime]::Now).ToString("yyyy-MM-dd"))",

    [Parameter(Mandatory=$false,Position=4,ValueFromPipelineByPropertyName=$true)]
    [ValidateSet('Vuln_Hosts_Summary','Vuln_By_Host','Compliance_Exec','Remediations','Vuln_By_Plugin','Compliance','All')]
    [string[]]$Chapters = 'All',

    [Parameter(Mandatory=$false,Position=5,ValueFromPipelineByPropertyName=$true)]
    [ValidateSet('Nessus','HTML','PDF','CSV')]
    [string[]]$Formats = @("PDF","Nessus"),

    [Parameter(Mandatory=$false,Position=6,ValueFromPipelineByPropertyName=$true)]
    [string]$SecurePassword,

    [Parameter(Mandatory=$false,Position=6,ValueFromPipelineByPropertyName=$true)]
    [string]$InsecurePassword
)


#------------------------------------------------------------[Functions]-----------------------------------------------------------
Function Write-nLog {
   Param (
        [Parameter(Mandatory=$True)]
        [ValidateSet('Debug','Error','Warning','Info')]
        [String]$Type,
        [Int]$ErrorCode,
        [Switch]$TerminatingError,
        [Parameter(Mandatory=$True)]
        [String[]]$Message,
        [Int]$LogLevel,
        [String]$LogFile="$env:ALLUSERSPROFILE\Scripts\Logs\$([io.path]::GetFileNameWithoutExtension($script:MyInvocation.MyCommand.path))`.log",
        [Switch]$WriteHost,
        [Switch]$WriteLog
    )
    
    #Initial Variables 
    $tTimeStamp       = [DateTime]::Now
    $tTimeStampString = $tTimeStamp.ToString("yyyy-mm-dd hh:mm:ss")
    
    [String]$ErrorCode = $ErrorCode.ToString("0000")

    #If Global LogLevel doesn't exist, create it
    IF (-Not (Test-Path variable:Script:nLogLogLevel)) {
        New-Variable -Name nLogLogLevel -Value 3 -Scope Script -Force
    }

    #Update Log Level if defined
    IF ($LogLevel) {
        Set-Variable -Name nLogLogLevel -Scope Script -Force -Value $LogLevel
    }

    IF ((Test-Path variable:Script:nLogWriteHost) -AND !$WriteHost) {
        $WriteHost = $Script:nLogWriteHost
    }

    IF ((Test-Path variable:Script:nLogWriteLog) -AND !$WriteLog) {
        $WriteLog = $Script:nLogWriteLog
    }

    #Ensure we have the timestamp of last entry for debug time differences
    IF (-Not (Test-Path variable:Script:nLogLastTimeStamp)) {
        New-Variable -Name nLogLastTimeStamp -Value $tTimeStamp -Scope Script -Force
    }
    $tDifference = " ($(((New-TimeSpan -Start $Script:nLogLastTimeStamp -End $tTimeStamp).Seconds).ToString(`"0000`"))`s)"

    #Lets create a Host Timestamp
    IF ($WriteHost) {
        Switch ($Type) {
            {$Type -eq 'Debug'   -AND $Script:nLogLogLevel -EQ 1} { Write-Host "[DEBUG]   $tTimeStampString$tDifference`t$Message" -ForegroundColor Cyan             }
            {$Type -eq 'Info'    -AND $Script:nLogLogLevel -LE 2} { Write-Host "[INFO]    $tTimeStampString$tDifference`t$Message" -ForegroundColor White            }
            {$Type -eq 'Warning' -AND $Script:nLogLogLevel -LE 3} { Write-Host "[WARNING] $tTimeStampString$tDifference`t$Message" -ForegroundColor DarkRed          }
            {$Type -eq 'Error'   -AND $Script:nLogLogLevel -LE 4} { Write-Host "[ERROR]   $tTimeStampString$tDifference`t[$ErrorCode] $Message" -ForegroundColor Red }
        }
    }

    IF ($WriteLog) {
        Switch ($Type) {
            {$Type -eq 'Debug'   -AND $Script:nLogLogLevel -EQ 1} { "[DEBUG]   $tTimeStampString$tDifference`t$Message" | Out-file -FilePath $LogFile -Append              }
            {$Type -eq 'Info'    -AND $Script:nLogLogLevel -LE 2} { "[INFO]    $tTimeStampString$tDifference`t$Message" | Out-file -FilePath $LogFile -Append              }
            {$Type -eq 'Warning' -AND $Script:nLogLogLevel -LE 3} { "[WARNING] $tTimeStampString$tDifference`t$Message" | Out-file -FilePath $LogFile -Append              }
            {$Type -eq 'Error'   -AND $Script:nLogLogLevel -LE 4} { "[ERROR]   $tTimeStampString$tDifference`t[$ErrorCode] $Message" | Out-file -FilePath $LogFile -Append }
        }
    }
    
    #Ensure we have the timestamp of the last log execution.
    $Script:nLogLastTimeStamp = $tTimeStamp

    #Cleanup because ISE is a nightmare
    Get-Variable -Name "*t" -include '^t[A-Z].*' | Where-Object {$_.Name -cmatch '^t[A-Z].*'} |Remove-Variable

    #Allow us to exit the script from the logging function.
    If ($TerminatingError) {
        Exit
    }
}

Function New-NessusSession {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false,Position=0)]
        [string]$NessusServer = $Script:NessusServer,

        [Parameter(Mandatory=$false,Position=1)]
        [string]$Port = $Script:Port
    )

    $RestMethodParams = @{ 
        Uri           = "https://$($NessusServer):$Port/session"
        Method        = 'Post'
        Body          = @{'username' = $Username; 'password' = $Password}
        ErrorVariable = 'NessusLoginError'
    }

    Try {
        $RestMethod = Invoke-RestMethod @RestMethodParams
    } Catch {
        #Script unable to continue.
    }

    IF ([String]::IsNullOrEmpty($NessusLoginError)) {
        New-Variable -Name Session -Scope Script -Force -Value @{
            URI              = "https://$($NessusServer):$Port"
            Token            = $RestMethod.Token
            SessionStartTime = [DateTime]::Now
        }
        Write-nLog -Type Debug -Message "Generated session token: $($RestMethod.Token)"
    } Else {
        Write-nLog -Type Error -TerminatingError -Message "Unable to generate session token with $NessusServer."
    }
}

Function Invoke-NessusRequest {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false)]
        $Parameter,

        [Parameter(Mandatory=$true)]
        [string]$Path,

        [Parameter(Mandatory=$true)]
        [ValidateSet('Post','Get')]
        [String]$Method,

        [Parameter(Mandatory=$false)]
        [String]$OutFile,

        [Parameter(Mandatory=$false)]
        [String]$ContentType,

        [Parameter(Mandatory=$false)]
        [String]$InFile
    )
    $RestMethodParams = @{
        'Method'        = $Method
        'URI'           =  "$($Script:Session.URI)$($Path)"
        'Headers'       = @{'X-Cookie' = "token=$($Script:Session.Token)"}
        'ErrorVariable' = 'NessusUserError'
    }
    if ($Parameter) {
        $RestMethodParams.Add('Body', $Parameter)
    }

    if($OutFile) {
        $RestMethodParams.add('OutFile', $OutFile)
    }

    if($ContentType) {
        $RestMethodParams.add('ContentType', $ContentType)
    }

    if($InFile) {
        $RestMethodParams.add('InFile', $InFile)
    }

    Try {
        $Results = Invoke-RestMethod @RestMethodParams
    } Catch [Net.WebException] {
        IF ([Int]$_.Exception.Response.StatusCode -eq 401) {
            Write-nLog -Message "Session has expired, reauthenticating" -Type Info
            New-NessusSession

            #Need to update the header with new session token and resubmit.
            Write-nLog -Message "Resubmitting query with new session token" -Type Debug
            $RestMethodParams.headers = @{'X-Cookie' = "token=$($Script:Session.Token)"}
            $Results = Invoke-RestMethod @RestMethodParams
        }
    }

    IF ([String]::IsNullOrEmpty($NessusUserError)) {
        $Script:Test = $RestMethodParams.header
        Write-nLog -Type Debug -Message "Successfully executed Invoke-NessusRequest."
        IF ($RestMethodParams.body) {
            Write-nLog -Type Debug -Message "Method = '$($RestMethodParams.Method)' | URI = '$($RestMethodParams.URI)' | Headers = '$(($RestMethodParams.Headers.GetEnumerator() | % { "$($_.Name)=$($_.Value)" }) -join ",")' | OutFile = '$($RestMethodParams.OutFile)' | ContentType = '$($RestMethodParams.ContentType)' | InFile = '$($RestMethodParams.InFile)' | Body = '$(($RestMethodParams.body.GetEnumerator() | % { "$($_.Name)=$($_.Value)" }) -join ",")'"
        } Else {
            Write-nLog -Type Debug -Message "Method = '$($RestMethodParams.Method)' | URI = '$($RestMethodParams.URI)' | Headers = '$(($RestMethodParams.Headers.GetEnumerator() | % { "$($_.Name)=$($_.Value)" }) -join ",")' | OutFile = '$($RestMethodParams.OutFile)' | ContentType = '$($RestMethodParams.ContentType)' | InFile = '$($RestMethodParams.InFile)'"
        }
        Return $Results
    } Else {

    }
}

Function Export-NessusReport {
    Param (
        [Parameter(ValueFromPipelineByPropertyName=$true,Position=0)]
        [Int32]$ScanID,

        [Parameter(ValueFromPipelineByPropertyName=$true,Position=1)]
        [String]$ScanName,

        [Parameter(Mandatory=$false,Position=2,ValueFromPipelineByPropertyName=$true)]
        [ValidateSet('Nessus','HTML','PDF','CSV')]
        [string[]]$Formats = $Script:Formats,

        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,Position=3)]
        [String]$OutputDir = $Script:OutputDir,

        [Parameter(Mandatory=$false,Position=4,ValueFromPipelineByPropertyName=$true)]
        [ValidateSet('Vuln_Hosts_Summary','Vuln_By_Host','Compliance_Exec','Remediations','Vuln_By_Plugin','Compliance','All')]
        [string[]]$Chapters = $Script:Chapters
    )

    If ($Chapters -contains 'All') {
        $ParamChapters = "vuln_hosts_summary;vuln_by_host;compliance_exec;remediations;vuln_by_plugin;compliance"
    } else {
        $ParamChapters = $Chapters.ToLower()
    }

    ForEach ($Format in $Formats) {
        $ExportParams = @{
            format   = $format.ToLower()
            chapters = $ParamChapters
        }

        Write-nLog -Type Info -Message "Exporting '$ScanName' in format '$Format' to '$OutputDir'"
        $File = (Invoke-NessusRequest -Path "/scans/$ScanID/export" -Method Post -Parameter $ExportParams).file
        IF ([String]::IsNullOrEmpty($File)) {
            Write-nLog -Type Error -Message "Unable to generate file ID for $ScanName." -WriteHost
        } Else {
            $ExportTime = [DateTime]::Now
            $Status = $Null
            $Outfile = "$OutputDir\$($ScanName.Replace(" ","-"))`.$Format"
            [Int]$ElapsedTime = 0

            While ($Status -ne 'ready') {
                Try {
                    $ElapsedTime = (New-TimeSpan -Start $ExportTime -End ([DateTime]::now)).TotalSeconds
                    $Status = (Invoke-NessusRequest -Path "/scans/$ScanId/export/$File/status" -Method 'Get').status
                    Write-nLog -Message "Status of export is '$Status'. (Elapsed time: $ElapsedTime`s)" -Type Debug
                    Start-Sleep -Seconds 5
                } Catch {
                    Break
                }
            }
        
            Write-nLog -Type Info -Message "Downloading report to $OutFile" -WriteHost
            IF ([System.io.file]::Exists($OutFile)) {
                Write-nLog -Type Info -Message "File already exists so removing file: $Outfile"
                Remove-Item -Path $Outfile -Force
            }
            Invoke-NessusRequest -Path "/scans/$ScanId/export/$File/download" -Method 'Get' -OutFile $OutFile

        }
    }
}
#----------------------------------------------------------[Prerequisites]---------------------------------------------------------
#Sources: (2), (3)
Try {
Add-Type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
    ServicePoint srvPoint, X509Certificate certificate,
    WebRequest request, int certificateProblem) {
        return true;
    }
}
"@
} Catch {
    IF ($Error[0].Exception -NotLike "*The type name * already exists*") {
       Write-Error -Exception $Error[0].Exception
       break
    }
}
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
[System.Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#------------------Input Variables----------------------------------------------------------------- 
#use different password if in ISE or not
If (Test-Path variable:global:psISE) {
    $nlogWriteHost = $True
    $nLogLogLevel = 1

}
IF ([String]::IsNullOrEmpty($SecurePassword)) {
    $SecurePassword = $SecurePassword | ConvertTo-SecureString
    $Marshal = [System.Runtime.InteropServices.Marshal]
    $Bstr = $Marshal::SecureStringToBSTR($SecurePassword)
    $Password = $Marshal::PtrToStringAuto($Bstr)
    $Marshal::ZeroFreeBSTR($Bstr)
} ElseIF ([String]::IsNullOrEmpty($InsecurePassword)) {

} Else {
    Write-nLog -Type Error -TerminatingError -Message "No password provided."
    exit 1
}

#Ensure Logs are written.
$nlogWriteHost = $True

#Create Initial Nessus Session
New-NessusSession

#Create output dir if doesn't exist
IF (![System.IO.Directory]::Exists($OutputDir)) {
    New-Item -Path $OutputDir  -ItemType directory -Force |Out-Null
}

#Remove items older than 30 days in path parent folder.
Get-ChildItem –Path $(Split-Path $OutputDir) -Recurse | Where-Object {($_.LastWriteTime -lt ([DateTime]::Now).AddDays(-30))} | Remove-Item -Recurse -whatif

#------------------Output completed scans---------------------------------------------------------- 
$Scans = (invoke-NessusRequest -Path "/scans" -Method "GET").scans.where({$_.name -like "*(E)*"})
#$Scans = (invoke-NessusRequest -Path "/scans" -Method "GET").scans.where({$_.name -like "*Shadow*"})

ForEach ($Scan in $Scans) {
    Export-NessusReport -Formats $Formats -OutputDir $OutputDir -Chapters $Chapters -ScanID $Scan.id -ScanName $Scan.name
}
