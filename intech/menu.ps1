function menu {
    try {
        $choice = read-option -options $([ordered]@{
                "Add InTechAdmin" = "Create the InTechAdmin local account."
                "Nuvia"           = "View the Nuvia menu."
            })

        if ($choice -eq 0) { $command = "intech add admin" }
        if ($choice -eq 1) { $command = "nuvia menu" }

        read-command -command $command
    } catch {
        exit-script -Type "error" -Text "windows-menu-$($_.InvocationInfo.ScriptLineNumber) | $($_.Exception.Message)" -LineAfter
    }
}

