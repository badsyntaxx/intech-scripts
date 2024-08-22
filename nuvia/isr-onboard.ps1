function isr-onboard {
    $funcs = @(
        "edit hostname" 
        "nuvia isr install apps"
        "intech add admin"
        "nuvia install bginfo"
        "toggle context menu"
        "plugins reclaim"
    )

    foreach ($func in $funcs) {
        add-func -command $func
    }

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

        # Create the main script file
        New-Item -Path "$env:SystemRoot\Temp\CHASTE-Script.ps1" -ItemType File -Force | Out-Null

        add-script -subPath $subPath -script $fileFunc
        add-script -subpath "core" -script "framework"

        Add-Content -Path "$env:SystemRoot\Temp\CHASTE-Script.ps1" -Value @"
function run-all {
    edit-hostname 
    isr-install-apps
    add-admin
    install-bginfo
    toggle-context-menu
    reclaim
}
"@
        # Add a final line that will invoke the desired function
        Add-Content -Path "$env:SystemRoot\Temp\CHASTE-Script.ps1" -Value "invoke-script 'run-all'"
    } catch {
        # Error handling: display an error message and prompt for a new command
        Write-Host "  $($_.Exception.Message) | init-$($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
    }
}

