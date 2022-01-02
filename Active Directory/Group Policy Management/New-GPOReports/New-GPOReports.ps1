<#
    .SYNOPSIS
        Generate a HTML report of all GPOs within the domain. 

    .DESCRIPTION
        Create a HTML report of all GPOs within the domain. 
        
    .PARAMETER ExportPath
        (Optional) Specify a directory in which you want the GPOs to be exported to. If nothing is specified it will create a folder in the same directory as the script and export there. 
        
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
        (2) https://virot.eu/cleaning-downloaded-filenames-of-invalid-characters/
#>

Param (
    $ExportPath = "$(Split-Path $script:MyInvocation.MyCommand.Path)\HTMLReports-$(([DateTime]::Now).toString('dd-MM-yyyy'))"
)

if (-not ([System.IO.Directory]::Exists($ExportPath))) {
    try {
        New-Item -Path $ExportPath -ItemType Directory -ErrorAction Stop | Out-Null #-Force
        Write-Output -InputObject "Successfully created directory: '$ExportPath'."
    }
    catch {
        Write-Error -Message "Unable to create directory: '$ExportPath'. Error was: $_" -ErrorAction Stop
    }
}

Get-GPO -all | ForEach-Object {
    IF (-NOT [String]::IsNullOrEmpty($_.ID)) {
        $Test = $_
        Try {
            Write-Output -InputObject "[Info] Attempting to process GPO '$($_.DisplayName)'."
            Get-GPOReport -GUID $_.id -ReportType HTML -Path “$ExportPath\$($_.displayName -replace "[$([string]::join('',([System.IO.Path]::GetInvalidFileNameChars())) -replace '\\','\\')]",'_').html” |Out-Null
            Write-Output -InputObject "[Success] Successfully processed GPO '$($_.DisplayName)'."
        } Catch {
            Break
            Write-Output -InputObject "[Error] Failed to process GPO '$($_.DisplayName)'. (Error: $($Error[0].Exception.Message))"
        }
    }
}
