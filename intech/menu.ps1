function menu {
    try {
        $choice = read-option -options $([ordered]@{
                "Add InTechAdmin" = "Create the InTechAdmin local account."
                "Nuvia"           = "View the Nuvia menu."
                "Cancel"          = "Select nothing and exit this menu."
            }) -prompt "Select an InTech function:"

        switch ($choice) {
            0 { $command = "intech add admin" }
            1 { $command = "nuvia menu" }
            2 { read-command }
        }

        Write-Host
        Write-Host ": "  -ForegroundColor "DarkCyan" -NoNewline
        Write-Host "Running command:" -NoNewline -ForegroundColor "DarkGray"
        Write-Host " $command" -ForegroundColor "Gray"

        read-command -command $command
    } catch {
        write-text -type "error" -text "intech-menu-$($_.InvocationInfo.ScriptLineNumber) | $($_.Exception.Message)" -lineAfter
        read-command
    }
}

