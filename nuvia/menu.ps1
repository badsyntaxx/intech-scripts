function menu {
    try {
        $choice = read-option -options $([ordered]@{
                "Install TScan"     = "Install TScan software."
                "ISR Onboard"       = "Collection of functions to onboard and ISR computer."
                "ISR Install Apps"  = "Install all the apps an ISR needs to work."
                "ISR Install Ninja" = "Install Ninja for ISR computers."
                "ISR Add Bookmarks" = "Add ISR bookmarks to Chrome."
            })

        if ($choice -eq 0) { $command = "nuvia install tscan" }
        if ($choice -eq 1) { $command = "nuvia isr onboard" }
        if ($choice -eq 2) { $command = "nuvia isr install apps" }
        if ($choice -eq 3) { $command = "nuvia isr install ninja" }
        if ($choice -eq 4) { $command = "nuvia isr add bookmarks" }

        read-command -command $command
    } catch {
        exit-script -type "error" -text "nuvia-menu: $($_.Exception.Message) $url/nuvia/$dependency.ps1" 
    }
}

