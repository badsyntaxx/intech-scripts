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
        }

        if ($choice -ne 3) {
            $url = "https://app.ninjarmm.com/agent/installer/0274c0c3-3ec8-44fc-93cb-79e96f191e07/$location-5.9.1158-windows-installer.msi"
            $service = Get-Service -Name "NinjaRMMAgent" -ErrorAction SilentlyContinue

            writeText -type "notice" -text "$location-5.9.1158-windows-installer.msi"
        
            if ($null -ne $service -and $service.Status -eq "Running") {
                writeText -type "success" -text "NinjaRMMAgent is already installed and running."
            } else {
                $download = getDownload -url $url -target "$env:SystemRoot\Temp\NinjaOne.msi" -lineBefore
                if ($download) { 
                    Start-Process -FilePath "msiexec" -ArgumentList "/i `"$env:SystemRoot\Temp\NinjaOne.msi`" /qn" -Wait

                    # Initialize variables for service check
                    $maxAttempts = 10  # Number of attempts to check service
                    $waitSeconds = 5   # Time to wait between attempts
                    $serviceRunning = $false

                    writeText -type "notice" -text "Waiting for NinjaRMMAgent service to start..."

                    # Loop to check service status
                    for ($i = 1; $i -le $maxAttempts; $i++) {
                        $service = Get-Service -Name "NinjaRMMAgent" -ErrorAction SilentlyContinue
                        
                        if ($null -ne $service) {
                            if ($service.Status -eq "Running") {
                                $serviceRunning = $true
                                break
                            } elseif ($service.Status -ne "Running") {
                                writeText -type "notice" -text "Attempt $i of $maxAttempts`: Service found but not running. Starting service..."
                                Start-Service -Name "NinjaRMMAgent" -ErrorAction SilentlyContinue
                            }
                        } else {
                            writeText -type "notice" -text "Waiting for Ninja service to start..."
                        }

                        if ($i -lt $maxAttempts) {
                            Start-Sleep -Seconds $waitSeconds
                        }
                    }

                    # Cleanup
                    Get-Item -ErrorAction SilentlyContinue "$env:SystemRoot\Temp\NinjaOne.msi" | Remove-Item -ErrorAction SilentlyContinue

                    # Final status check
                    if ($serviceRunning) {
                        writeText -type "success" -text "NinjaOne successfully installed and service is running." -lineAfter
                    }
                    else {
                        throw "NinjaOne installation completed but service failed to start after $($maxAttempts * $waitSeconds) seconds."
                    }
                }
            }
        }
    } catch {
        writeText -type "error" -text "installNinja-$($_.InvocationInfo.ScriptLineNumber) - $($_.Exception.Message)"
    }
}