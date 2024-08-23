function isr-install-ninja {
    try {
        $choice = read-option -options $([ordered]@{
                "Inventory"   = "Install for inventory."
                "Orem Center" = "Install for the Orem ISR center."
                "Remote"      = "Install for a remote ISR."
            }) -prompt "Install for the Orem ISR center or other?"

        $location = "nuviainventory"

        switch ($choice) {
            1 { $location = "nuviaisrcenteroremut" }
            2 { $location = "nuviaisrcenterremote" }
        }

        $url = "https://app.ninjarmm.com/agent/installer/0274c0c3-3ec8-44fc-93cb-79e96f191e07/$location-5.9.1158-windows-installer.msi"
        $service = Get-Service -Name "NinjaRMMAgent" -ErrorAction SilentlyContinue

        write-text -type "notice" -text "$location-5.9.1158-windows-installer.msi" -lineBefore
        
        if ($null -ne $service -and $service.Status -eq "Running") {
            write-text -type "success" -text "NinjaRMMAgent is already installed and running."s
        } 

        $download = get-download -Url $Url -Target "$env:SystemRoot\Temp\NinjaOne.msi" -visible
        if (!$download) { throw "Unable to acquire intaller." }
          
        Start-Process -FilePath "msiexec" -ArgumentList "/i `"$env:SystemRoot\Temp\NinjaOne.msi`" /qn" -Wait

        Start-Sleep -Seconds 3

        $service = Get-Service -Name "NinjaRMMAgent" -ErrorAction SilentlyContinue
        if ($null -eq $service -or $service.Status -ne "Running") { throw "NinjaOne did not successfully install." }

        Get-Item -ErrorAction SilentlyContinue "$env:SystemRoot\Temp\NinjaOne.msi" | Remove-Item -ErrorAction SilentlyContinue

        write-text -type "success" -text "NinjaOne successfully installed." -lineAfter
    } catch {
        # Display error message and end the script
        write-text -type "error" -text "isr-install-ninja-$($_.InvocationInfo.ScriptLineNumber) - $($_.Exception.Message)"
    }
}

