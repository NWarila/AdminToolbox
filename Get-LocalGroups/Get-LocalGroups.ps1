New-Variable -name ADSI -value (([ADSI]"WinNT://localhost").psbase.children) -Force -ErrorAction Stop
New-Variable -Name LocalGroups -Value (New-Object System.Collections.ArrayList) -Force -ErrorAction Stop
New-Variable -Name GroupTypes -Force -Value @{"2" = "Global";"4" = "DomainLocal";"8" = "Universal"}
New-Variable -Name GroupLocation -Force -Value @{"$env:USERDOMAIN" = "Domain";"NT AUTHORITY" = "Local";"$ENV:COMPUTERNAME" = "Local"}
$ADSI | Where-Object {$_.schemaClassName -match "group"} |select -Skip 1 | foreach-object {
    Write-Host "Processing: $($_.Name.Value)"
    $Group = [PSCustomObject]@{
        Name                       = $_.name.value -as [string]
        GroupType                  = $GroupTypes["$($_.GroupType.value)"] -As [String]
        Description                = $_.Description.value -as [string]
        SID                        = (New-Object System.Security.Principal.SecurityIdentifier($_.objectSid.value,0)).Value -as [String]            
        Members                    = New-Object System.Collections.ArrayList
    }
    ([ADSI]$_.psbase.Path).psbase.Invoke("Members") | ForEach-Object {
        [void]$Group.Members.Add([PSCustomObject]@{
            Name      = $_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)
            SID       = (New-Object System.Security.Principal.SecurityIdentifier($_.GetType().InvokeMember("ObjectSID", 'GetProperty', $null, $_, $null),0)).value
            ADsPath   = $_.GetType().InvokeMember("ADsPath", 'GetProperty', $null, $_, $null)
            GroupType = $GroupLocation["$($_.GetType().InvokeMember('ADsPath', 'GetProperty', $null, $_, $null).split('/')[2])"]
        })
    }
    [Void]$LocalGroups.Add($Group)
}
