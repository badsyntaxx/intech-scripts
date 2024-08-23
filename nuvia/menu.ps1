function menu {
    try {
        $choice = read-option -options $([ordered]@{
                "Install TScan"     = "Install TScan software."
                "ISR Onboard"       = "Collection of functions to onboard and ISR computer."
                "ISR Install Apps"  = "Install all the apps an ISR needs to work."
                "ISR Install Ninja" = "Install Ninja for ISR computers."
                "ISR Add Bookmarks" = "Add ISR bookmarks to Chrome."
            }) -prompt "Select a Nuvia function:"

        switch ($choice) {
            0 { $command = "nuvia install tscan" }
            1 { $command = "nuvia isr onboard" }
            2 { $command = "nuvia isr install apps" }
            3 { $command = "nuvia isr install ninja" }
            4 { $command = "nuvia isr add bookmarks" }
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

