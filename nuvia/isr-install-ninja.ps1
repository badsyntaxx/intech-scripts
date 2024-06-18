function isr-install-ninja {
    try {
        $url = "https://app.ninjarmm.com/agent/installer/0274c0c3-3ec8-44fc-93cb-79e96f191e07/nuviaisrcenteroremut-5.8.9154-windows-installer.msi"
        $service = Get-Service -Name "NinjaRMMAgent" -ErrorAction SilentlyContinue

        write-text -type "notice" -text "Accessing nuviaisrcenteroremut-5.8.9154-windows-installer.msi" -lineBefore -lineAfter
        
        if ($null -ne $service -and $service.Status -eq "Running") {
            write-text -type "plain" -text "NinjaRMMAgent is already installed and running."
            read-command
        } 

        $download = get-download -Url $Url -Target "$env:TEMP\NinjaOne.msi"
        if (!$download) { throw "Unable to acquire intaller." }
          
        Start-Process -FilePath "msiexec" -ArgumentList "/i `"$env:TEMP\NinjaOne.msi`" /qn" -Wait

        $service = Get-Service -Name "NinjaRMMAgent" -ErrorAction SilentlyContinue
        if ($null -eq $service -or $service.Status -ne "Running") { throw "NinjaOne did not successfully install." }

        Get-Item -ErrorAction SilentlyContinue "$env:TEMP\NinjaOne.msi" | Remove-Item -ErrorAction SilentlyContinue

        exit-script -type "success" -text "NinjaOne successfully installed." -lineAfter
    } catch {
        # Display error message and end the script
        exit-script -type "error" -text "isr-install-ninja-$($_.InvocationInfo.ScriptLineNumber) - $($_.Exception.Message)"
    }
}

