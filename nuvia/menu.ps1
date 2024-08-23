function menu {
    try {
        $choice = read-option -options $([ordered]@{
                "ISR menu"          = "Go to the Nuvia ISR menu."
                "Install TScan"     = "Install TScan software."
                "Install Ninja"     = "Install Ninja for Nuvia computers."
                "Install JumpCloud" = "Install JumpCloud for Nuvia computers."
                "Cancel"            = "Select nothing and exit this menu."
            }) -prompt "Select a Nuvia function:"

        switch ($choice) {
            0 { $command = "nuvia isr menu" }
            1 { $command = "nuvia install-tscan" }
            2 { $command = "nuvia install ninja" }
            3 { $command = "nuvia install jumpcloud" }
            4 { read-command }
        }

        Write-Host
        Write-Host ": "  -ForegroundColor "DarkCyan" -NoNewline
        Write-Host "Running command:" -NoNewline -ForegroundColor "DarkGray"
        Write-Host " $command" -ForegroundColor "Gray"

        read-command -command $command
    } catch {
        write-text -type "error" -text "nuvia-menu: $($_.Exception.Message) $url/nuvia/$dependency.ps1" 
        read-command
    }
}

