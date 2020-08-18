<#
    .SYNOPSIS
        Generate report of inactive user accounts.

    .DESCRIPTION
        

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
#>

Param (
    [Parameter(Position=0,ValueFromPipelineByPropertyName=$True)]
    [Int]$DaysInactive = 30,

    [Parameter(Position=1,ValueFromPipelineByPropertyName=$True)]
    [string[]]$ExclusionGroups = @("UCMS_ServiceAccounts","UCMS_SYSAccounts_SU")
)

Function Get-GroupMembers {
    Param (
        [Parameter(Mandatory=$True)]
        [String]$Group
    )
    New-Variable -Name Result -Force -ErrorAction Stop -Value $(New-Object System.Collections.ArrayList)
    Write-host -InputObject "[Debug] Processing $Group"
    Get-ADGroup -Filter {Name -eq $Group} | Get-ADGroupMember | ForEach-Object {
        IF ($_.ObjectClass -eq "User") {
            [Void]$Result.Add([PSCustomObject]@{
                Name              = $_.Name
                SamAccountName    = $_.SamAccountName
                ObjectClass       = $_.ObjectClass
                SID               = $_.SID
                DistinguishedName = $_.DistinguishedName
            })
        } ElseIF ($_.ObjectClass -eq "Group") {
            Get-GroupMembers -group $_.Name |ForEach-Object { [Void]$Result.Add($_) }
        } Else {
            Write-Output -InputObject "[Error] Unknown Object Class '$($_.ObjectClass)'"
        }
    }
    Return $Result
}

New-Variable -Name Script -Force -ErrorAction Stop -Value @{
    StartTime        = [DateTime]::Now
    DomainContollers = Get-ADDomainController -Filter * -Server (Get-ADDomain).DNSRoot
    ActiveDCs        = New-Object -TypeName System.Collections.ArrayList
    JobResults       = New-Object System.Collections.ArrayList
    Results          = New-Object System.Collections.ArrayList
    ExcludedUsers    = New-Object System.Collections.ArrayList
}

#Get a list of active Domain Controllers
ForEach ($DC in $Script.DomainContollers) { 
    IF (Test-Connection -Computername $DC.Hostname -Count 5 -Quiet) {
      [Void]$Script.ActiveDCs.Add($DC)
    } Else {
         Write-Warning -Message "Domain Controller $($DC.Name) is unreachable."
    }
}

$tRunspaceCollection = @()
$tRunSpacePool = [RunspaceFactory]::CreateRunspacePool(1, [int]$env:NUMBER_OF_PROCESSORS + 1)
$tRunSpacePool.ApartmentState = "MTA"
$tRunSpacePool.Open()

$tScriptblock = {
    Param (
        [string]$Server
    )
    Get-ADUser -Filter {Enabled -EQ $True} -Properties Name,SamAccountName,Enabled,LockedOut,PasswordNeverExpires,badpwdcount,LastLogon,"msDS-UserPasswordExpiryTimeComputed" -Server $Server | select Name,SamAccountName,Enabled,LockedOut,@{Name='BadPwdCount';Expression={[Int]$_.BadPwdCount}},PasswordNeverExpires,@{Name='LastLogon';Expression={[DateTime]::FromFileTime($_.LastLogon)}},@{Name='PasswordExpiration';Expression={[DateTime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed")}},@{Name='DomainController';Expression={$Server}}
}

#Run the Get-ADUser command against all reachable Domain Controllers.
ForEach ($DC in $Script.ActiveDCs) {
    Write-Host "Starting Job against $DC"
	$tJob = [PowerShell]::Create().AddScript($tScriptBlock).AddArgument($DC.HostName)
	$tJob.RunspacePool = $tRunspacePool
	[Collections.Arraylist]$tRunspaceCollection += New-Object -TypeName PSObject -Property @{
		Runspace = $tJob.BeginInvoke()
		PowerShell = $tJob
	}
}

While($tRunspaceCollection) {
	Foreach ($tRunspace in $tRunspaceCollection.ToArray()) {
		If ($tRunspace.Runspace.IsCompleted) {
            $tRunspace.PowerShell.EndInvoke($tRunspace.Runspace) |ForEach-Object {[Void]$Script.JobResults.Add($_)}
			$tRunspace.PowerShell.Dispose()
			$tRunspaceCollection.Remove($tRunspace)
		} #/If
	} #/ForEach
} #/While
$tRunSpacePool.Close()
$tRunSpacePool.Dispose()

$Script.JobResults | Foreach-Object {$_.LastLogon = [DateTime]$_.LastLogon; $_} | Group-Object Name | Foreach-Object {$_.Group | Sort-Object LastLogon | Select-Object -Last 1} |ForEach-Object {
    [Void]$Script.Results.Add([PSCustomObject]@{
        Name                 = $_.Name
        Enabled              = $_.Enabled
        LockedOut            = $_.LockedOut
        BadPwdCount          = $_.BadPwdCount
        PasswordNeverExpires = $_.PasswordNeverExpires
        LastLogon            = $_.LastLogon
        PasswordExpiration   = IF (!$_.Enabled) {"N/A"} ElseIF ($_.PasswordNeverExpires -OR !($_.PasswordExpiration -as [DateTime])) {"Never"} Else {($_.PasswordExpiration - ($Script.StartTime)).Days}
        DomainController     = $_.DomainController
        SinceLogon           = $Script.StartTime - $_.LastLogon
        SamAccountName       = $_.SamAccountName
    })
}

ForEach ($Group in $ExclusionGroups) {
    Get-GroupMembers -Group $Group |ForEach-Object {
        #Write-Output -InputObject "[Debug] Adding $($_.name)"
        [Void]$Script.ExcludedUsers.Add($_)
    }
}

$Script.Results |Where-Object {$_.SinceLogon.Days -ge $DaysInactive -AND $Script.ExcludedUsers.name -NotContains $_.Name} |Select Name,@{Name="Last Logon (Days)";Expression={$_.SinceLogon.Days}},SamAccountName |Sort-Object -Property Name
