function global:prompt {

    #Get last command executed
    New-Variable -Name Success -Value ($script:?) -Force
    New-Variable -Name LastCommand -Value (Get-History -Count 1) -Force
    
	
    #Test if admin or not
	IF(-NOT (Test-path Variable:\Global:Prompt)) {
        
		New-Variable -Name Prompt -Scope Global -Force -ErrorAction Stop -Value @{
			IsAdmin = [Bool](New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
            PWD     = $PWD.path
        }

        #Set Once Configuration Options
	    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
	    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
	    Set-PSReadLineOption -EditMode Emacs

	    #Remove ding-dong sound
	    Set-PSReadlineOption -BellStyle None

        $Console = $Host.ui.RawUI
        $Console.BackgroundColor = "Black"
        $Console.ForegroundColor = "Green"
        $host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size(228,32000)
        Clear-Host
    }

    #Set Powershell title to Current Directory Path
    IF ($host.ui.RawUI.WindowTitle -ne "Powershell v$($PSVersionTable['PSVersion'].Major)`.$($PSVersionTable['PSVersion'].Minor) | PDW: $($PWD.path)") {
	    $host.ui.RawUI.WindowTitle = "Powershell v$($PSVersionTable['PSVersion'].Major)`.$($PSVersionTable['PSVersion'].Minor) | PDW: $($PWD.path)"
        $Global:Prompt.PWD = $PWD.path
    }
    
    #Timespan for last executed command
    IF ([String]::IsNullOrWhiteSpace($LastCommand)) {
        New-Variable -Name LastCommandTimeSpan -value (New-TimeSpan) -Force
    } Else {
        New-Variable -Name LastCommandTimeSpan -Value (New-TimeSpan -Start $LastCommand.StartExecutionTime -End $LastCommand.EndExecutionTime) -Force
    }
    

    #= Lets build the main line. =#
    #Write a bir red "!" if last command failed.
    IF ($Success -eq $False) {
        Write-Host -Object "!" -NoNewline -BackgroundColor DarkRed
    }

    #Write Time last command took to execute
    Write-Host -Object "[$($LastCommandTimeSpan.TotalMinutes.ToString('00')):$($LastCommandTimeSpan.ToString('ss\:ff'))]" -NoNewline

    #Write username + Computername
    Write-Host -Object "$ENV:Username@$ENV:COMPUTERNAME" -NoNewline


    IF ($Global:Prompt.IsAdmin) {
	    Return "# "
    } Else {
        Return "$ "
    }
}
