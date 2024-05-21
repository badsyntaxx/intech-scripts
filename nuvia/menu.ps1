function menu {
    try {
        clear-host
        write-welcome -Title "Nuvia Menu" -Description "Select an action to take." -Command "menu"

        $url = "https://raw.githubusercontent.com/badsyntaxx/chased-intech-scripts/main"

        write-text -Type "header" -Text "Selection" -LineAfter -LineBefore
        $choice = get-option -Options $([ordered]@{
                "Install TScan"     = "Install TScan software."
                "ISR Onboard"       = "Collection of functions to onboard and ISR computer."
                "ISR Install Apps"  = "Install all the apps an ISR needs to work."
                "ISR Install Ninja" = "Install Ninja for ISR computers."
                "ISR Add Bookmarks" = "Add ISR bookmarks to Chrome."
            }) -LineAfter

        if ($choice -eq 0) { $command = "nuvia install tscan" }
        if ($choice -eq 1) { $command = "nuvia isr onboard" }
        if ($choice -eq 2) { $command = "nuvia isr install apps" }
        if ($choice -eq 3) { $command = "nuvia isr install ninja" }
        if ($choice -eq 4) { $command = "nuvia isr add bookmarks" }

        get-cscommand -command $command
    } catch {
        exit-script -Type "error" -Text "Menu error: $($_.Exception.Message) $url/nuvia/$dependency.ps1" 
    }
}

