function intech {
    Write-Host
    Write-Host "  Try" -NoNewline
    Write-Host " intech help" -ForegroundColor "Cyan" -NoNewline
    Write-Host " or" -NoNewline
    Write-Host " intech menu" -NoNewline -ForegroundColor "Cyan"
    Write-Host " if you don't know what to do."
}
function writeHelp {
    writeText -type "plain" -text "COMMANDS:"
    writeText -type "plain" -text "intech add admin  - Create the InTech admin account." -Color "DarkGray"
    writeText -type "plain" -text "schedule reboot   - Schedule a reboot for Wednesday at 10PM" -Color "DarkGray"
}
function readMenu {
    try {
        $choice = readOption -options $([ordered]@{
                "Add InTechAdmin" = "Create the InTechAdmin local account."
                "Nuvia"           = "View the Nuvia menu."
                "Cancel"          = "Select nothing and exit this menu."
            }) -prompt "Select an InTech function:"

        switch ($choice) {
            0 { $command = "intech add admin" }
            1 { $command = "nuvia menu" }
            2 { readCommand }
        }

        Write-Host
        Write-Host ": "  -ForegroundColor "DarkCyan" -NoNewline
        Write-Host "Running command:" -NoNewline -ForegroundColor "DarkGray"
        Write-Host " $command" -ForegroundColor "Gray"

        readCommand -command $command
    } catch {
        writeText -type "error" -text "intech-menu-$($_.InvocationInfo.ScriptLineNumber) | $($_.Exception.Message)" -lineAfter
        readCommand
    }
}