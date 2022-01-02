PARAM(
    [Int]$PasswordLength            = 127,
    [Int]$MinUpperCase              = 5,
    [Int]$MinLowerCase              = 5,
    [Int]$MinSpecialCharacters      = 5,
    [Int]$MinNumbers                = 5,
    [Int]$ConsecutiveCharClass      = 0,
    [Int]$ConsecutiveCharCheckCount = 100,
    [String]$LowerCase              = 'abcdefghiklmnoprstuvwxyz',
    [String]$UpperCase              = 'ABCDEFGHKLMNOPRSTUVWXYZ',
    [String]$Numbers                = '1234567890',
    [String]$SpecialCharacters      = '!"$%&/()=?}][{@#*+'
)

#Define default special characters
New-Variable -Name CharacterClasses -Force -Value ([PSCustomObject]@{
    LowerCase         = $LowerCase
    UpperCase         = $UpperCase
    Numbers           = $Numbers
    SpecialCharacters = $SpecialCharacters
    CombinedClasses   = $LowerCase,$UpperCase,$Numbers,$SpecialCharacters -join ''
})

$CreatePassword = [scriptblock]::Create({
    New-Variable -Name NewPassword -Value ([System.Text.StringBuilder]::new()) -Force

    #Meet the minimum requirements for each character class
    ForEach ($CharacterClass in @("MinUpperCase","MinLowerCase","MinSpecialCharacters","MinNumbers")) {
        New-Variable -name Characters -Force -Value @{
            Class = $CharacterClass.SubString(3) -As [String]
            Characters = $CharacterClasses.($CharacterClass.SubString(3)) -As [String]
            MinCharacters = (Get-Variable $CharacterClass -ValueOnly) -as [Int]
        }
        If (-Not [String]::IsNullOrEmpty($Characters.Characters)) {
            If ($Characters.MinCharacters -gt 0) {
                $Chars = 1..$($Characters.MinCharacters) | ForEach-Object {Get-Random -Maximum $Characters.Characters.length}
                [void]$NewPassword.Append(([String]$Characters.Characters[$Chars] -replace " ",""))
            }
        }
    }

    #Now meet the minimum length requirements.
    $Chars = 1..($PasswordLength - $NewPassword.Length) |ForEach-Object {Get-Random -Maximum $CharacterClasses.CombinedClasses.length}
    [void]$NewPassword.Append(([String]$CharacterClasses.CombinedClasses[$Chars] -replace " ",""))

    $FinalPassword = ([Char[]]$NewPassword.ToString() | Sort-Object {Get-Random}) -join ""
    Return $FinalPassword
})

Switch ([Int]$ConsecutiveCharClass) {
    '0' { New-Variable -Name NewPassword -Value (& $CreatePassword) -Force }
    '1' { 
        Write-Warning Testing
        Write-Host test
    }
    {$_ -ge 2} {
        New-Variable -Name CheckPass -Value $False -Force
        New-Variable -Name CheckCount -Value ([Int]0) -Force
        While ($CheckCount -lt $ConsecutiveCharCheckCount -AND $CheckPass -eq $False) {
            New-Variable -Name NewPassword -Value (& $CreatePassword) -Force
            ForEach ($CharacterClass in ("LowerCase","UpperCase","Numbers","SpecialCharacters")) {
                IF (-Not [String]::IsNullOrEmpty($CharacterClasses.$CharacterClass)) {                      
                    #The Actual Check
                    if ($NewPassword -cmatch "([$([Regex]::Escape([char[]]($CharacterClasses.$CharacterClass) -join ","))]{$ConsecutiveCharClass,})" -eq $True) {
                        $CheckCount++
                        break
                    }
                    $CheckPass = $True
                }
            }
        }
        If ($CheckPass -eq $False) {
            Write-Warning -Message "Unable to find a password combination that meets ConsecutiveCharCheck requirements."
            Remove-Variable -Name NewPassword -Force
        }
    }
    Default {Write-Warning -Message "This shouldn't be possible, how did you get here?!"}
}
Return $NewPassword
