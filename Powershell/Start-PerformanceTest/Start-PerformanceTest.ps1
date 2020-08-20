Function Start-PerformanceTest {
    <#
        .SYNOPSIS
            Test the execution time of script blocks.

        .DESCRIPTION
            Perform an accurate measurement of a block of code over a number of itterations allowing informed decisions to be made about code efficency. 

        .PARAMETER ScriptBlock
            [ScriptBlock] Code to run and measure. Input code as either a ScriptBlock object or wrap it in {} and the script will attempt to convert it automatically.

        .PARAMETER Measurement
            [String] Ime interval in which to display measurements. (Options: Milliseconds, Seconds, Minutes, Hours, Days)

        .PARAMETER Itterations
            [Int] Numbers of times to run the code.
        
        .INPUTS
            None

        .OUTPUTS
            None

        .NOTES

        VERSION     DATE			NAME						DESCRIPTION
	    ___________________________________________________________________________________________________________
	    1.0         20 August 2020	Warilia, Nicholas R.		Initial version

        Credits:
            (1) Script Template: https://gist.github.com/9to5IT/9620683
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ScriptBlock]$ScriptBlock,
        [ValidateSet("Milliseconds",“Seconds”,”Minutes”,”Hours”,"Days")]
        $Measurement = "Seconds",
        [int]$Iterations = 100
    )

    $Results = [System.Collections.ArrayList]::new()

    For ($I=0;$I -le $Iterations;$I++) {
        [Void]$Results.Add(
            ((Measure-Command -Expression ([scriptblock]::Create($ScriptBlock)) |Select-Object TotalDays,TotalMinutes,TotalSeconds,TotalMilliseconds))
        )
    }

    #Determine correct timestamp label
    Switch ($Measurement) {
        'Milliseconds' {$LengthType = "ms"}
        default        {$LengthType = $Measurement.SubString(0,1).tolower()}
    }

    $Results |Group-Object Total$Measurement |Measure-Object -Property Name -Average -Maximum -Minimum | Select-Object `
            @{Name="Maximum";Expression={"$([Math]::Round($_.Maximum,3))$LengthType"}},
            @{Name="Minimum";Expression={"$([Math]::Round($_.Minimum,3))$LengthType"}},
            @{Name="Average";Expression={"$([Math]::Round($_.Average,3))$LengthType"}}
}
