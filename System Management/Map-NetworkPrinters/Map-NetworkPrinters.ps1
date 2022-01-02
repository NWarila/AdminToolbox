<#
    .SYNOPSIS
        Reads INI file set by GPO and maps printers listed in the config file. 

    .DESCRIPTION
        
    .PARAMETER <Parameter_Name>

    .INPUTS
        None

    .OUTPUTS
        None

    .NOTES
	VERSION     DATE			NAME						DESCRIPTION
	___________________________________________________________________________________________________________
	1.0         07 March 2020	Warilia, Nicholas R.		Initial version

    Credits:
        Get-IniContent Script: https://gallery.technet.microsoft.com/scriptcenter/ea40c1ef-c856-434b-b8fb-ebd7a76e8d91
#>

Function Get-IniContent {  
    [CmdletBinding()]  
    Param(  
        [ValidateNotNullOrEmpty()]  
        [ValidateScript({(Test-Path $_)})]
        [Parameter(ValueFromPipeline=$True,Mandatory=$True)]
        [string]$FilePath  
    )  
    Begin  
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}  
          
    Process  
    {  
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing file: $Filepath"  
              
        $ini = @{}  
        switch -regex -file $FilePath  
        {  
            "^\[(.+)\]$" # Section  
            {  
                $section = $matches[1]  
                $ini[$section] = @{}  
                $CommentCount = 0  
            }  
            "^(;.*)$" # Comment  
            {  
                if (!($section))  
                {  
                    $section = "No-Section"  
                    $ini[$section] = @{}  
                }  
                $value = $matches[1]  
                $CommentCount = $CommentCount + 1  
                $name = "Comment" + $CommentCount  
                $ini[$section][$name] = $value  
            }   
            "(.+?)\s*=\s*(.*)" # Key  
            {  
                if (!($section))  
                {  
                    $section = "No-Section"  
                    $ini[$section] = @{}  
                }  
                $name,$value = $matches[1..2]  
                $ini[$section][$name] = $value  
            }  
        }  
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Processing file: $FilePath"  
        Return $ini 
    }  
          
    End  
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}  
} 

New-Variable -Name INP -Force -ErrorAction Stop -Value @{
    PrintersDB     = @()
    SiteID         = Get-IniContent -FilePath "$($env:USERPROFILE)\SiteID.ini"
    MappedPrinters = Get-Printer |Where-Object {$_.Type -ne 'Local'}
}

ForEach ($Printer in $INP.SiteID.Printers.keys) {
    $tPrintReg = [Regex]::Matches($INP.SiteID.Printers[$Printer],"'([^']+)'=`"([^`"]+)`";?")
    $tPrinter = @{
        Name = ($Printer |Out-String).trim()
    }
    For ($I=0; $I -lt $tPrintReg.Captures.Count; $I++) {
        $tPrinter.($tPrintReg.captures[$i].groups[1].Value) = $tPrintReg.captures[$i].groups[2].value
    }
    $INP.PrintersDB += [PSCustomObject]$tPrinter
}

ForEach ($Printer in $INP.PrintersDB) {
    If ($INP.MappedPrinters.count -gt 0 -AND $INP.MappedPrinters.name.Contains($Printer.Path)) {
        $tMapped = $Flase
    } Else {
        $tMapped = $True
    }
    Switch ($Printer.Action) {
        'Add'   { 
            if ($tMapped) {
                Add-Printer -ConnectionName $Printer.Path
            }
        }
        'Remove' {
            if (!$tMapped) {
                Remove-Printer -Name $Printer.Path
            }
        }
        Default { Write-Host $Printer }
    }
}
