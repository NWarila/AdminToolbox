Function Create-RandomStringv1 {
    Param (
        [int]$Size=10485760
    )

    #https://powershelladministrator.com/2015/11/15/speed-of-loops-and-different-ways-of-writing-to-files-which-is-the-quickest/

    #Initialize a new instance of the crypto provider
    New-Variable -Force -Name CryptoProvider -Value (new-Object System.Security.Cryptography.RNGCryptoServiceProvider)

    #Create a completely random character database that is 255 characters long.
    New-Variable -Force -Name Dictionary     -Value ([System.Collections.Generic.List[char]]::new())
    New-Variable -Force -Name Characters     -Value ([Text.encoding]::UTF8.GetChars((33..127)))
    $Characters | & { Process { $Dictionary.Add($_) } }
    
    New-Variable -Force -Name RemainingChars -Value (255-$Characters.Length)
    New-Variable -Force -Name DictBytes      -Value ([System.Byte[]]::new($RemainingChars))
    $CryptoProvider.GetNonZeroBytes($DictBytes)
    $DictBytes | & { process {
            $Dictionary.Add(($Characters[$_ % $Characters.Length]))
        }
    }

    $Dictionary = {$Dictionary}.Invoke()

    #Now that we have a functional dictionary to reference lets get to work creating randomness
    New-Variable -Force -Name ByteArray    -Value ([System.Byte[]]::new($Size))
    New-Variable -Force -Name StreamWriter -Value (New-Object -TypeName System.IO.Streamwriter -ArgumentList ("D:\Desktop\TestFile.txt"),$False,([Text.Encoding]::UTF8))
    $CryptoProvider.GetNonZeroBytes($ByteArray)
    $StreamWriter.Write([char[]]$Dictionary[$ByteArray])
    $StreamWriter.Close()
    $StreamWriter.Dispose()
}

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

Start-PerformanceTest -ScriptBlock {Create-RandomStringv1 -Size (1024*1024*100)} -Iterations 1 -Measurement Seconds
