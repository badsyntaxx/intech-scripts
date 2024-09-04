function installNinja {
    try {
        $choice = readOption -options $([ordered]@{
                "Inventory"   = "Install for inventory."
                "Orem Center" = "Install for the Orem ISR center."
                "ISR Remote"  = "Install for a remote ISR."
                "Cancel"      = "Install nothing and exit this function."
            }) -prompt "Install for the Orem ISR center or other?"

        $location = "nuviainventory"

        switch ($choice) {
            1 { $location = "nuviaisrcenteroremut" }
            2 { $location = "nuviaisrcenterremote" }
            3 { readCommand }
        }

        $url = "https://app.ninjarmm.com/agent/installer/0274c0c3-3ec8-44fc-93cb-79e96f191e07/$location-5.9.1158-windows-installer.msi"
        $service = Get-Service -Name "NinjaRMMAgent" -ErrorAction SilentlyContinue

        writeText -type "notice" -text "$location-5.9.1158-windows-installer.msi"
        
        if ($null -ne $service -and $service.Status -eq "Running") {
            writeText -type "success" -text "NinjaRMMAgent is already installed and running."
        } else {
            $download = getDownload -url $url -target "$env:SystemRoot\Temp\NinjaOne.msi" 
            if ($download) { 
                Start-Process -FilePath "msiexec" -ArgumentList "/i `"$env:SystemRoot\Temp\NinjaOne.msi`" /qn" -Wait

                Start-Sleep -Seconds 3

                $service = Get-Service -Name "NinjaRMMAgent" -ErrorAction SilentlyContinue
                if ($null -eq $service -or $service.Status -ne "Running") { throw "NinjaOne did not successfully install." }

                Get-Item -ErrorAction SilentlyContinue "$env:SystemRoot\Temp\NinjaOne.msi" | Remove-Item -ErrorAction SilentlyContinue

                writeText -type "success" -text "NinjaOne successfully installed." -lineAfter
            }
        }
    } catch {
        writeText -type "error" -text "installNinja-$($_.InvocationInfo.ScriptLineNumber) - $($_.Exception.Message)"
    }
}

