1..256 | ForEach-Object -Process:({
    $Int = $_
    $Name = "$([char]$Int) - $('{0:d3}' -f $Int)"
    Try {
        New-Item -Name:$Name -ErrorAction:Stop
    } Catch {
        If ($Error[0].Exception.Message -eq 'Illegal characters in path.') {
            Write-Warning -Message:"Character '$([char]$Int)' is invalid."
            New-Item -Name:"Invalid Character - $('{0:d3}' -f $Int)" -ErrorAction:SilentlyContinue
        } ElseIf ($Error[0].Exception.Message -like "The file '*' already exists.") {
            Write-Verbose -Message:"File '$Name' already exists."
        }
    }
})
