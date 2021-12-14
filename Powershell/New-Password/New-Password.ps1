
PARAM(
    [Int]$PasswordLength            = 127,
    [Int]$MinUpperCase              = 5,
    [Int]$MinLowerCase              = 5,
    [Int]$MinSpecialCharacters      = 5,
    [Int]$MinNumbers                = 5,
    [Int]$ConsecutiveCharClass      = 0,
    [Int]$ConsecutiveCharCheckCount = 1000,
    [String]$LowerCase              = 'abcdefghiklmnoprstuvwxyz',
    [String]$UpperCase              = 'ABCDEFGHKLMNOPRSTUVWXYZ',
    [String]$Numbers                = '1234567890',
    [String]$SpecialCharacters      = '!"$%&/()=?}][{@#*+',
    [String]$PasswordProfile        = '',

    #Advanced Options
    [Bool]$EnhancedEntrophy = $True
)

If ([String]::IsNullOrEmpty($PasswordProfile) -eq $False) {
    #You can define custom password profiles here for easy reference later on.
    New-Variable -Force -Name:'PasswordProfiles' -Value:@{
        'iDrac' = [PSCustomObject]@{PasswordLength=20;SpecialCharacters="+&?>-}|.!(',_[`"@#)*;$]/§%=<:{@";}
    }

    If ($PasswordProfile -in $PasswordProfiles.Keys) {
        $PasswordProfiles[$PasswordProfile] |Get-Member -MemberType NoteProperty |ForEach-Object {
            Set-Variable -Name $_.name -Value $PasswordProfiles[$PasswordProfile].($_.name)
        }
    }
}

New-Variable -Force -Name:'PassBldr' -Value @{}
New-Variable -Force -Name:'CharacterClass' -Value:([String]::Empty)
ForEach ($CharacterClass in @("UpperCase","LowerCase","SpecialCharacters","Numbers")) {
    $Characters = (Get-Variable -Name:$CharacterClass -ValueOnly)
    If ($Characters.Length -gt 0) {
        $PassBldr[$CharacterClass] = [PSCustomObject]@{
            Min        = (Get-Variable -Name:"min$CharacterClass" -ValueOnly);
            Characters = $Characters
            Length     = $Characters.length
        }
    }
}

#Sanity Check(s)
$MinimumChars = $MinUpperCase + $MinLowerCase + $MinSpecialCharacters + $MinNumbers
If ($MinimumChars -gt $PasswordLength) {
    Write-Error -Message:"Specified number of minimum characters ($MinimumChars) is greater than password length ($PasswordLength)."
    Return
}

#New-Variable -Force -Name:'Random' -Value:(New-Object -TypeName:'System.Random')
New-Variable -Force -Name:'Randomizer' -Value:$Null
New-Variable -Force -Name:'Random' -Value:([ScriptBlock]::Create({
    Param([Int]$Max=[Int32]::MaxValue,[Int32]$Min=1)
    if ($Min -gt $Max) {
        Write-Warning  "[$($myinvocation.ScriptLineNumber)] Min ($Min) must be less than Max ($Max)."
        return -1
    }

    if ($EnhancedEntrophy) {
        if ($Randomizer -eq $Null) {
            Set-Variable -Name:'Randomizer' -Value:(New-Object -TypeName:'System.Security.Cryptography.RNGCryptoServiceProvider') -Scope:1
        }
        #initialize everything
        $Difference=$Max-$Min
        [Byte[]] $bytes = 1..4  #4 byte array for int32/uint32

        #generate the number
        $Randomizer.getbytes($bytes)
        $Number = [System.BitConverter]::ToUInt32(($bytes),0)
        return ([Int32]($Number % $Difference + $Min))

    } Else {
        if ($Randomizer -eq $Null) {
            Set-Variable -Name:'Randomizer' -Value:(New-Object -TypeName:'System.Random') -Scope:1
        }
        return ([Int]$Randomizer.Next($Min,$Max))
    }
}))

$GetString = [ScriptBlock]::Create({
    Param([Int]$Length,[String]$Characters)
    Return ([String]$Characters[(1..$Length |ForEach-Object {& $Random $Characters.length})] -replace " ","")
})

$CreatePassword = [scriptblock]::Create({
    New-Variable -Name Password -Value ([System.Text.StringBuilder]::new()) -Force

    #Meet the minimum requirements for each character class
    ForEach ($CharacterClass in $PassBldr.Values) {
        If ($CharacterClass.Min -gt 0) {
            $Null = $Password.Append([string](Invoke-Command $GetString -ArgumentList $CharacterClass.Min,$CharacterClass.Characters))
        }
    }

    #Now meet the minimum length requirements.
    If ([Int]($PasswordLength-$Password.length) -gt 0) {
        $Null = $Password.Append((Invoke-Command $GetString -ArgumentList ($PasswordLength-$Password.length),($PassBldr.Values.Characters -join "")))
    }

    return (([Char[]]$Password.ToString() | Get-Random -Count $Password.Length) -join "")
})

Switch ([Int]$ConsecutiveCharClass) {
    '0' { New-Variable -Name NewPassword -Value (& $CreatePassword) -Force }
    {$_ -gt 0} {
        New-Variable -Name CheckPass    -Value $False -Force
        New-Variable -Name CheckCount   -Value ([Int]0) -Force
        For ($I=0; $I -le $ConsecutiveCharCheckCount -and $CheckPass -eq $False; $I++) {
            New-Variable -Name NewPassword -Value (& $CreatePassword) -Force
            $TestPassed = 0
            ForEach ($CharClass in $PassBldr.Values) {                   
                IF ([Regex]::IsMatch([Regex]::Escape($NewPassword),"[$([Regex]::Escape($CharClass.Characters))]{$ConsecutiveCharClass}") -eq $False) {
                    $TestPassed++
                }
            }
            if ($TestPassed -eq $CheckClasses.Count) {
                $CheckPass = $True
            }
        }
    }
    Default {Write-Warning -Message "This shouldn't be possible, how did you get here?!"}
}

Return $NewPassword