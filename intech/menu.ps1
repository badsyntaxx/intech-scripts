function menu {
    try {
        clear-host
        write-welcome -Title "Windows Menu" -Description "Select an action to take." -Command "windows menu"

        write-text -Type "header" -Text "Selection" -LineAfter -LineBefore
        $choice = get-option -Options $([ordered]@{
                "Add InTechAdmin" = "Create the InTechAdmin local account."
            }) -LineAfter

        if ($choice -eq 0) { $command = "intech add intechadmin" }

        get-cscommand -command $command
    } catch {
        exit-script -Type "error" -Text "windows-menu-$($_.InvocationInfo.ScriptLineNumber) | $($_.Exception.Message)" -LineAfter
    }
}

