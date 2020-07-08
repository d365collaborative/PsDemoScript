<#
.SYNOPSIS
Start a PowerShell demo

.DESCRIPTION
Start a PowerShell demo based on a prepared script file

.PARAMETER File
Path to the file that contains the demo script that you want to run

.PARAMETER TypingSpeed
Number of milliseconds the demo should add between each characther typed during the demo

.PARAMETER Mode
Instruct the cmdlet to either run the code, or to echo the code to the console or don't run anything

Valid options:
Execute
Echo
Silent

.PARAMETER MockCommandsFile
Path to the file that contains the mocked cmdlet / functions that you have prepared along your demo

Useful when you want to use invalid secret details in your demo, but still produce real data

Also useful for prepping output data, that should always be outputted, regardless of where you run your demo

.PARAMETER SkipExitPrompt
Instruct the cmdlet to skip the exit prompt notification

.EXAMPLE
PS C:\> Start-PsDemo -Path "c:\temp\demo.txt"

This will run the prepared demo.

.NOTES

Author: Mötz Jensen (@Splaxi)

#>
Function Start-PsDemo {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingInvokeExpression", "")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseOutputTypeCorrectly", "")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]

    [cmdletBinding()]

    Param(
        [Parameter(Mandatory = $True)]
        [ValidateScript( { Test-Path $_ })]
        [Alias('Path')]
        [string] $File,

        [ValidateScript( { $_ -gt 0 })]
        [int] $TypingSpeed = 80,
        
        [ValidateSet('Execute', 'Echo', 'Silent')]
        [string] $Mode = "Execute",

        [string] $MockCommandsFile,

        [switch] $SkipExitPrompt
    )
    
    #https://stackoverflow.com/questions/13710453/how-can-i-remove-a-dot-sourced-script-in-powershell
    if (-not [System.String]::IsNullOrEmpty($MockCommandsFile)) {
        ."$MockCommandsFile"
    }

    $originalLocation = Get-Location

    $colorCommandName = "Yellow"
    $colorParam = "DarkGray"
    $colParmValue = "DarkCyan"
    $colorVariable = "Green"
    $colorText = "White"

    # $colorOperator = "DarkGray"
    # $operatorList = @("+", "/", "*")

    Function PauseIt {
        [CmdletBinding()]
        Param()

        $Running = $true

        While ($Running) {
            if ($host.ui.RawUi.KeyAvailable) {
                $key = $host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                if ($key) {
                    $Running = $False
                    
                    #check the value and if it is q or ESC, then bail out
                    if ($key -match "q|27") {
                        Microsoft.PowerShell.Utility\Write-Host "`r"
                        if (-not [System.String]::IsNullOrEmpty($MockCommandsFile)) {
                            Get-ChildItem function: | Where-Object { $_.ScriptBlock.File -eq $MockCommandsFile } | Remove-Item
                        }

                        return "quit"
                    }
                    elseif ($key -match "f") {
                        return "fastforward"
                    }
                    elseif ($key -match "n") {
                        return "normal"
                    }
                }
            }

            Start-Sleep -millisecond 100
        }
    }

    #abort if running in the ISE
    if ($host.name -match "PowerShell ISE") {
        Write-PSFMessage -Level "Warning" -Message "This will not work in the ISE. Use the PowerShell console host."
        Return
    }

    Clear-Host

    #strip out all comments and blank lines
    Write-PSFMessage -Level "Verbose" -Message "Getting commands from $file"

    $commands = Get-Content -Path $file | Where-Object { $_ -NotMatch "#" -AND $_ -Match "\w|::|{|}|\(|\)" }

    $count = 0

    #write a prompt using your current prompt function
    Microsoft.PowerShell.Utility\Write-Host $(prompt) -NoNewline

    $NoMultiLine = $True
    $StartMulti = $False

    $interval = {
        $TypingSpeed
    }

    Write-PSFMessage -Level "Verbose" -Message "Defining PipeCheck Scriptblock"
    $PipeCheck = {
        if ($command[$i] -eq "|") {
            $resPause = PauseIt
            If ($resPause -eq "quit") { Return }
            elseif ($resPause -eq "fastforward") { return "fastforward" }
            elseif ($resPause -eq "normal") { return "normal" }
        }
    }

    $PauseCharacterCheck = {
        If ($command[$i] -eq "þ") {
            $resPause = PauseIt
            If ($resPause -eq "quit") { Return }
            elseif ($resPause -eq "fastforward") { return "fastforward" }
            elseif ($resPause -eq "normal") { return "normal" }
        }
    }

    foreach ($command in $commands) {
        $command = $command.Trim()
  
        $interval = {
            $TypingSpeed
        }

        $count++

        #pause until a key is pressed which will then process the next command
        if ($NoMultiLine) {
            $resPause = PauseIt
            If ($resPause -eq "quit") { Return }
            elseif ($resPause -eq "fastforward") { $interval = { 1 } }
            elseif ($resPause -eq "normal") { $interval = { $TypingSpeed } }
        }
   
        $firstSpace = $false
        $firstQuote = $false
        $QuoteChar = ""
        $commandSeparatorActive = $false

        $color = $colorCommandName

        #SINGLE LINE COMMAND
        if ($command -ne "::" -AND $NoMultiLine) {
            Write-PSFMessage -Level "Verbose" -Message "single line command"
            for ($i = 0; $i -lt $command.length; $i++) {
     
                $resPauseCheck = $(&$PauseCharacterCheck)
                if ($resPauseCheck -eq "fastforward") {
                    $interval = { 1 }
                }
                elseif ($resPauseCheck -eq "normal") {
                    $interval = { $TypingSpeed }
                }
                
                if ($($command[$i]) -eq "þ") {
                    continue
                }

                switch ($($command[$i])) {
                    " " {
                        if (-not ($commandSeparatorActive) -and (-not ($firstQuote))) {
                            $firstSpace = $true
                            $color = $colorText
                        }
                    }
                    "|" {
                        if (-not ($firstQuote)) {
                            $commandSeparatorActive = $true
                            $firstSpace = $false
                            $color = $colorText
                        }
                    }
                    ";" {
                        if (-not ($firstQuote)) {
                            $commandSeparatorActive = $true
                            $firstSpace = $false
                            $color = $colorText
                        }
                    }
                    "=" {
                        if (-not ($firstQuote)) {
                            $commandSeparatorActive = $true
                            $firstSpace = $false
                            $color = $colorParam
                        }
                    }
                    { $_ -in "-", "–" } {
                        if ($firstSpace) {
                            if (-not ($firstQuote)) {
                                $color = $colorParam
                            }
                        }
                    }
                    { $_ -in "$", "@" } {
                        if (-not ($firstQuote)) {
                            $color = $colorVariable
                        }
                    }
                    { $_ -in '"', "'" } {
                        if (-not ($firstQuote)) {
                            $firstQuote = $true
                            $QuoteChar = $_
                        }
                        else {
                            if ($QuoteChar -eq $_) {
                                $firstQuote = $false
                                $QuoteChar = ""
                            }
                        }

                        $color = $colParmValue
                    }
                    default {
                        if ($commandSeparatorActive) {
                            $color = $colorCommandName
                            $commandSeparatorActive = $false
                        }
                    }
                }
                
                $char = $command[$i]

                Write-PSFHostColor -String "$char" -NoNewLine -DefaultColor $color

                #insert a pause to simulate typing
                Start-sleep -Milliseconds $(&$Interval)

                $resPipeCheck = $(&$PipeCheck)
                if ($resPipeCheck -eq "fastforward") {
                    $interval = { 1 }
                }
                elseif ($resPipeCheck -eq "normal") {
                    $interval = { $TypingSpeed }
                }
            }
    
            #remove the backtick line continuation character (if any)
            $command = $command.Replace('`', "")
    
            #Pause until ready to run the command
            $resPause = PauseIt
            If ($resPause -eq "quit") { Return }
            elseif ($resPause -eq "fastforward") { $interval = { 1 } }
            elseif ($resPause -eq "normal") { $interval = { $TypingSpeed } }

            Microsoft.PowerShell.Utility\Write-Host "`r"

            $command = $command -replace "þ", ""

            if ($Mode -eq "Execute") {
                Invoke-Expression $command | Out-Default
            }
            elseif ($Mode -eq "Echo") {
                Microsoft.PowerShell.Utility\Write-Host $command -ForegroundColor Cyan
            }
            elseif ($Mode -eq "Silent") {
                Write-PSFMessage -Level "Verbose" -Message -Message $command
            }
        }
        #IF SINGLE COMMAND
        #START MULTILINE
        #skip the ::
        elseif ($command -eq "::" -AND $NoMultiLine) {
            $NoMultiLine = $False
            $StartMulti = $True
            [string]$multi = ""
        } #elseif
        #FIRST LINE OF MULTILINE
        elseif ($StartMulti) {
            for ($i = 0; $i -lt $command.length; $i++) {
                $resPauseCheck = $(&$PauseCharacterCheck)
                if ($resPauseCheck -eq "fastforward") {
                    $interval = { 1 }
                }
                elseif ($resPauseCheck -eq "normal") {
                    $interval = { $TypingSpeed }
                }
                
                if ($($command[$i]) -eq "þ") {
                    continue
                }

                switch ($($command[$i])) {
                    " " {
                        if (-not ($commandSeparatorActive) -and (-not ($firstQuote))) {
                            $firstSpace = $true
                            $color = $colorText
                        }
                    }
                    "|" {
                        if (-not ($firstQuote)) {
                            $commandSeparatorActive = $true
                            $firstSpace = $false
                            $color = $colorText
                        }
                    }
                    ";" {
                        if (-not ($firstQuote)) {
                            $commandSeparatorActive = $true
                            $firstSpace = $false
                            $color = $colorText
                        }
                    }
                    "=" {
                        if (-not ($firstQuote)) {
                            $commandSeparatorActive = $true
                            $firstSpace = $false
                            $color = $colorParam
                        }
                    }
                    { $_ -in "-", "–" } {
                        if ($firstSpace) {
                            if (-not ($firstQuote)) {
                                $color = $colorParam
                            }
                        }
                    }
                    { $_ -in "$", "@" } {
                        if (-not ($firstQuote)) {
                            $color = $colorVariable
                        }
                    }
                    { $_ -in '"', "'" } {
                        if (-not ($firstQuote)) {
                            $firstQuote = $true
                            $QuoteChar = $_
                        }
                        else {
                            if ($QuoteChar -eq $_) {
                                $firstQuote = $false
                                $QuoteChar = ""
                            }
                        }

                        $color = $colParmValue
                    }
                    default {
                        if ($commandSeparatorActive) {
                            $color = $colorCommandName
                            $commandSeparatorActive = $false
                        }
                    }
                }
                
                $char = $command[$i]

                if ($IncludeTypo -AND ($(&$Interval) -ge ($RandomMaximum - 5))) {
                    &$Typo
                }
                else {
                    Write-PSFHostColor -String "$char" -NoNewLine -DefaultColor $color
                }
                
                start-sleep -Milliseconds $(&$Interval)
                
                #only check for a pipe if we're not at the last character
                #because we're going to pause anyway
                if ($i -lt $command.length - 1) {
                    $resPipeCheck = $(&$PipeCheck)
                    if ($resPipeCheck -eq "fastforward") {
                        $interval = { 1 }
                    }
                    elseif ($resPipeCheck -eq "normal") {
                        $interval = { $TypingSpeed }
                    }
                }
            } #for
    
            $StartMulti = $False

            #add the command to the multiline variable
            $multi += " $command"
            if ($command -notmatch ',$|{$|}$|\|$|\($|`$') { $multi += " ; " }

            $resPause = PauseIt
            If ($resPause -eq "quit") { Return }
            elseif ($resPause -eq "fastforward") { $interval = { 1 } }
            elseif ($resPause -eq "normal") { $interval = { $TypingSpeed } }
        
        } #elseif
        #END OF MULTILINE
        elseif ($command -eq "::" -AND !$NoMultiLine) {
            $firstSpace = $false
            $color = $colorCommandName
            
            Microsoft.PowerShell.Utility\Write-Host "`r"
            Microsoft.PowerShell.Utility\Write-Host ">> " -NoNewline
            $NoMultiLine = $True

            $resPause = PauseIt
            If ($resPause -eq "quit") { Return }
            elseif ($resPause -eq "fastforward") { $interval = { 1 } }
            elseif ($resPause -eq "normal") { $interval = { $TypingSpeed } }

            Microsoft.PowerShell.Utility\Write-Host "`r"

            $multi = $multi -replace "þ", ""
            $multi = $multi -replace '`', ""
            
            if ($Mode -eq "Execute") {
                Invoke-Expression $multi | Out-Default
            }
            elseif ($Mode -eq "Echo") {
                Microsoft.PowerShell.Utility\Write-Host $multi -ForegroundColor Cyan
            }
        }  #elseif end of multiline
        #NESTED PROMPTS
        else {
            $firstSpace = $false
            $color = $colorCommandName

            Microsoft.PowerShell.Utility\Write-Host "`r"
            Microsoft.PowerShell.Utility\Write-Host ">> " -NoNewLine
            
            $resPause = PauseIt
            If ($resPause -eq "quit") { Return }
            elseif ($resPause -eq "fastforward") { $interval = { 1 } }
            elseif ($resPause -eq "normal") { $interval = { $TypingSpeed } }

            for ($i = 0; $i -lt $command.length; $i++) {

                $resPauseCheck = $(&$PauseCharacterCheck)
                if ($resPauseCheck -eq "fastforward") {
                    $interval = { 1 }
                }
                elseif ($resPauseCheck -eq "normal") {
                    $interval = { $TypingSpeed }
                }

                if ($($command[$i]) -eq "þ") {
                    continue
                }

                switch ($($command[$i])) {
                    " " {
                        if (-not ($commandSeparatorActive) -and (-not ($firstQuote))) {
                            $firstSpace = $true
                            $color = $colorText
                        }
                    }
                    "|" {
                        if (-not ($firstQuote)) {
                            $commandSeparatorActive = $true
                            $firstSpace = $false
                            $color = $colorText
                        }
                    }
                    ";" {
                        if (-not ($firstQuote)) {
                            $commandSeparatorActive = $true
                            $firstSpace = $false
                            $color = $colorText
                        }
                    }
                    "=" {
                        if (-not ($firstQuote)) {
                            $commandSeparatorActive = $true
                            $firstSpace = $false
                            $color = $colorParam
                        }
                    }
                    '`' {
                        $previousColor = $color
                        $color = $colorText
                    }
                    { $_ -in "-", "–" } {
                        if (($firstSpace) -or ($i -eq 0)) {
                            if (-not ($firstQuote)) {
                                $color = $colorParam
                            }
                        }
                    }
                    { $_ -in "$", "@" } {
                        if (-not ($firstQuote)) {
                            $color = $colorVariable
                        }
                    }
                    { $_ -in '"', "'" } {
                        if (-not ($firstQuote)) {
                            $firstQuote = $true
                            $QuoteChar = $_
                        }
                        else {
                            if ($QuoteChar -eq $_) {
                                $firstQuote = $false
                                $QuoteChar = ""
                            }
                        }

                        $color = $colParmValue
                    }
                    default {
                        if ($commandSeparatorActive) {
                            $color = $colorCommandName
                            $commandSeparatorActive = $false
                        }
                    }
                }
                
                $char = $command[$i]

                Microsoft.PowerShell.Utility\Write-Host "$char" -NoNewLine -ForegroundColor $color

                if ($char -eq '`') {
                    $color = $previousColor
                }

                Start-Sleep -Milliseconds $(&$Interval)
                
                $resPipeCheck = $(&$PipeCheck)
                if ($resPipeCheck -eq "fastforward") {
                    $interval = { 1 }
                }
                elseif ($resPipeCheck -eq "normal") {
                    $interval = { $TypingSpeed }
                }
            }

            #add the command to the multiline variable and include the line break
            #character
            $multi += " $command"
    
            if ($command -notmatch ',$|{$|\|$|\($|`$') {
                $multi += " ; "
            }
        }
   
        #reset the prompt unless we've just done the last command
        if (($count -lt $commands.count) -AND ($NoMultiLine)) {
            Microsoft.PowerShell.Utility\Write-Host $(prompt) -NoNewline
        }
    }

    if (-not $SkipExitPrompt) {
        Microsoft.PowerShell.Utility\Write-Host $(prompt)
        Microsoft.PowerShell.Utility\Write-Host "Demo script is done. Exiting..." -ForegroundColor Cyan
        PauseIt
        Clear-Host
    }

    if (-not [System.String]::IsNullOrEmpty($originalLocation)) {
        Set-Location -Path $originalLocation
    }
}