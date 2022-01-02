
New-Variable -Name FIADU -Force -ErrorAction Stop -Value @{
    StartTime        = [DateTime]::Now
    DomainContollers = Get-ADDomainController -Filter * -Server (Get-ADDomain).DNSRoot
    ActiveDCs        = New-Object -TypeName System.Collections.ArrayList
    JobResults       = New-Object System.Collections.ArrayList
    Results          = New-Object System.Collections.ArrayList
}

$ExclusionGroups = "UCMS_ServiceAccounts","UCMS_SYSAccounts_SU"

#Get a list of active Domain Controllers
ForEach ($DC in $FIADU.DomainContollers) { 
    IF (Test-Connection -Computername $DC.Hostname -Count 5 -Quiet) {
      [Void]$FIADU.ActiveDCs.Add($DC)
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
ForEach ($DC in $FIADU.ActiveDCs) {
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
            $tRunspace.PowerShell.EndInvoke($tRunspace.Runspace) |ForEach-Object {[Void]$FIADU.JobResults.Add($_)}
			$tRunspace.PowerShell.Dispose()
			$tRunspaceCollection.Remove($tRunspace)
		} #/If
	} #/ForEach
} #/While
 
$tRunSpacePool.Close()
$tRunSpacePool.Dispose()

$FIADU.JobResults | Foreach-Object {$_.LastLogon = [DateTime]$_.LastLogon; $_} | Group-Object Name | Foreach-Object {$_.Group | Sort-Object LastLogon | Select-Object -Last 1} |ForEach-Object {
    [Void]$FIADU.Results.Add([PSCustomObject]@{
        Name                 = $_.Name
        Enabled              = $_.Enabled
        LockedOut            = $_.LockedOut
        BadPwdCount          = $_.BadPwdCount
        PasswordNeverExpires = $_.PasswordNeverExpires
        LastLogon            = $_.LastLogon
        PasswordExpiration   = IF (!$_.Enabled) {"N/A"} ElseIF ($_.PasswordNeverExpires -OR !($_.PasswordExpiration -as [DateTime])) {"Never"} Else {($_.PasswordExpiration - ($FIADU.StartTime)).Days}
        DomainController     = $_.DomainController
        SinceLogon           = $FIADU.StartTime - $_.LastLogon
        SamAccountName       = $_.SamAccountName
    })
}

ForEach ($Group in $ExclusionGroups) {
        Get-ADGroup -Filter {Name -eq $Group} | ForEach-Object {
            $FIADU.ExcludedUsers = Get-ADGroupMember -Identity $_.SamAccountName | Select-Object @{N='GroupName';E={$Group}},SamAccountName,Name
        }
    }
$FIADU.Results |Where-Object {$_.SinceLogon.Days -ge 30 -AND $FIADU.ExcludedUsers.name -notcontains $_.Name} |Select Name,@{Name="Last Logon (Days)";Expression={$_.SinceLogon.Days}},SamAccountName