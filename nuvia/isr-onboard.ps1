function isr-onboard {
    $funcs = @(
        "edit hostname" 
        "nuvia install ninja"
        "nuvia install jumpcloud"
        "nuvia isr install apps"
        "intech add admin"
        "nuvia install bginfo"
        "toggle context menu"
        "plugins reclaim"
    )

    # Create the main script file
    New-Item -Path "$env:SystemRoot\Temp\CHASTE-Script.ps1" -ItemType File -Force | Out-Null

    foreach ($func in $funcs) {
        add-func -command $func
    }

    add-onboardScript -subpath "core" -script "framework"

    Add-Content -Path "$env:SystemRoot\Temp\CHASTE-Script.ps1" -Value @"
function run-all {
    write-text -type "header" -text "Editing hostname" -lineBefore
    edit-hostname
    write-text -type "header" -text "Installing NinjaRMM" -lineBefore
    install-ninja 
    Write-Host
    write-text -type "header" -text "Installing JumpCloud" -lineBefore
    install-jumpcloud 
    write-text -type "header" -text "Installing ISR apps" -lineBefore
    isr-install-apps
    write-text -type "header" -text "Adding InTech admin" -lineBefore
    add-admin
    write-text -type "header" -text "Installing BGInfo" -lineBefore
    install-bginfo
    write-text -type "header" -text "Disabling context menu" -lineBefore
    toggle-context-menu
    write-text -type "header" -text "Debloating Windows" -lineBefore
    reclaim
}
"@
    # Add a final line that will invoke the desired function
    Add-Content -Path "$env:SystemRoot\Temp\CHASTE-Script.ps1" -Value "invoke-script 'run-all'"

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

        # Adjust command and paths
        $subCommands = @("plugins", "nuvia", "intech");
        $subPath = "windows"
        foreach ($sub in $subCommands) {
            if ($firstWord -eq $sub -and $firstWord -ne 'menu') { 
                $command = $command -replace "^$firstWord \s*", "" 
                $subPath = $sub
            }
        }

        # Convert command to title case and replace the first spaces with a dash and the second space with no space
        $lowercaseCommand = $command.ToLower()
        $fileFunc = $lowercaseCommand -replace ' ', '-'

        add-onboardScript -subPath $subPath -script $fileFunc
    } catch {
        # Error handling: display an error message and prompt for a new command
        Write-Host "  $($_.Exception.Message) | init-$($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
    }
}

function add-onboardScript {
    param (
        [Parameter(Mandatory)]
        [string]$subPath,
        [Parameter(Mandatory)]
        [string]$script,
        [Parameter(Mandatory = $false)]
        [string]$progressText
    )

    if ($subPath -eq 'windows' -or $subPath -eq 'plugins') {
        $url = "https://raw.githubusercontent.com/badsyntaxx/chaste-scripts/main"
    } else {
        $url = "https://raw.githubusercontent.com/badsyntaxx/intech-scripts/main"
    }

    # Download the script
    $download = get-download -Url "$url/$subPath/$script.ps1" -Target "$env:SystemRoot\Temp\$script.ps1" -failText "$url/$subPath/$script | Could not acquire onboarding components."
    
    if ($download) { 
        # Append the script to the main script
        $rawScript = Get-Content -Path "$env:SystemRoot\Temp\$script.ps1" -Raw -ErrorAction SilentlyContinue
        Add-Content -Path "$env:SystemRoot\Temp\CHASTE-Script.ps1" -Value $rawScript

        # Remove the script file
        Get-Item -ErrorAction SilentlyContinue "$env:SystemRoot\Temp\$script.ps1" | Remove-Item -ErrorAction SilentlyContinue
    }
}