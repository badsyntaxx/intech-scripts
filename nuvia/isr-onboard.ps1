function isr-onboard {
    $funcs = @(
        "edit hostname" 
        "nuvia install ninja"
        "nuvia install jumpcloud"
        "nuvia isr install apps"
        "intech add admin"
        "nuvia install bginfo"
        "toggle context menu"
        "plugins reclaimw11"
    )

    # Create the main script file
    New-Item -Path "$env:SystemRoot\Temp\CHASTE-Script.ps1" -ItemType File -Force | Out-Null

    foreach ($func in $funcs) {
        add-func -command $func
    }

    add-onboardScript -commandPath "core" -script "Framework"

    Add-Content -Path "$env:SystemRoot\Temp\CHASTE-Script.ps1" -Value @"
function run-all {
    writeText -type "header" -text "Editing hostname" -lineBefore
    edit-hostname
    writeText -type "header" -text "Installing NinjaRMM" -lineBefore
    install-ninja 
    Write-Host
    writeText -type "header" -text "Installing JumpCloud" -lineBefore
    install-jumpcloud 
    writeText -type "header" -text "Installing ISR apps" -lineBefore
    isr-install-apps
    writeText -type "header" -text "Adding InTech admin" -lineBefore
    add-admin
    writeText -type "header" -text "Installing BGInfo" -lineBefore
    install-bginfo
    writeText -type "header" -text "Disabling context menu" -lineBefore
    toggle-context-menu
    writeText -type "header" -text "Debloating Windows" -lineBefore
    reclaimw11
}
"@
    # Add a final line that will invoke the desired function
    Add-Content -Path "$env:SystemRoot\Temp\CHASTE-Script.ps1" -Value "invokeScript 'run-all'"

    # Execute the combined script
    $chasteScript = Get-Content -Path "$env:SystemRoot\Temp\CHASTE-Script.ps1" -Raw
    Invoke-Expression $chasteScript
}

function add-func {
    param (
        [Parameter(Mandatory = $false)]
        [string]$command = ""
    )

    try {
        if ($command -ne "" -and $command -match "^(?-i)(\w+(-\w+)*)") { 
            $firstWord = $matches[1] 
        }

        $commandPath = "windows"
        $potentialPaths = @("plugins", "nuvia", "intech");

        foreach ($pp in $potentialPaths) {
            if ($firstWord -eq $pp -and $firstWord -ne 'menu') { 
                $command = $command -replace "^$firstWord \s*", "" 
                $commandPath = $pp
            }
        }

        # Convert command to title case and replace the first spaces with a dash and the second space with no space
        $lowercaseCommand = $command.ToLower()
        $fileFunc = $lowercaseCommand -replace ' ', '-'

        add-onboardScript -commandPath $commandPath -script $fileFunc
    } catch {
        # Error handling: display an error message and prompt for a new command
        Write-Host "  $($_.Exception.Message) | init-$($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
    }
}

function add-onboardScript {
    param (
        [Parameter(Mandatory)]
        [string]$commandPath,
        [Parameter(Mandatory)]
        [string]$script,
        [Parameter(Mandatory = $false)]
        [string]$progressText
    )

    if ($commandPath -eq 'windows' -or $commandPath -eq 'plugins') {
        $url = "https://raw.githubusercontent.com/badsyntaxx/chaste-scripts/main"
    } else {
        $url = "https://raw.githubusercontent.com/badsyntaxx/intech-scripts/main"
    }

    # Download the script
    $download = getDownload -Url "$url/$commandPath/$script.ps1" -Target "$env:SystemRoot\Temp\$script.ps1" -failText "$url/$commandPath/$script | Could not acquire onboarding components."
    
    if ($download) { 
        # Append the script to the main script
        $rawScript = Get-Content -Path "$env:SystemRoot\Temp\$script.ps1" -Raw -ErrorAction SilentlyContinue
        Add-Content -Path "$env:SystemRoot\Temp\CHASTE-Script.ps1" -Value $rawScript

        # Remove the script file
        Get-Item -ErrorAction SilentlyContinue "$env:SystemRoot\Temp\$script.ps1" | Remove-Item -ErrorAction SilentlyContinue
    }
}