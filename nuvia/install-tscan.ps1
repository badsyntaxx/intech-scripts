function install-tscan {
    try {
        write-welcome -Title "Install T-Scan" -Description "Install T-Scan for Nuvia" -Command "intech install isr ninja"
        write-text -type "header" -text "Installing T-Scan for Nuvia" -lineBefore -lineAfter

        add-tscan-folder

        Set-Service -Name "SSDPSRV" -StartupType Automatic
        Start-Service -Name "SSDP Discovery"
        Set-Service -Name "upnphost" -StartupType Automatic
        Start-Service -Name "UPnP Device Host"
        Set-NetFirewallRule -DisplayGroup "Network Discovery" -Enabled True
        Set-NetFirewallRule -DisplayGroup "File and Printer Sharing" -Enabled True

        robocopy "\\NUVFULSVR\InTech\59179_T-Scan_v10_KALLIE_NUVIA_DENTAL_IMPLANT_CENTER" "$env:TEMP\tscan" /E /IS /COPYALL
          
        write-text "Installing T-Scan..."
        Start-Process -FilePath "$env:TEMP\tscan\tekscan\setup.exe" -ArgumentList "/quiet" -Wait
        write-text "T-Scan installed."
        
        Get-Item -ErrorAction SilentlyContinue "$env:TEMP\tscan" | Remove-Item -ErrorAction SilentlyContinue -Confirm $false
        exit-script
    } catch {
        exit-script -type "error" -text "Install error: $($_.Exception.Message)"
    }
}

function add-tscan-folder {
    try {
        write-text "Creating TScan folder..."
        write-text "$env:TEMP\tscan"

        if (-not (Test-Path -PathType Container "$env:TEMP\tscan")) {
            New-Item -Path "$env:TEMP" -Name "tscan" -ItemType Directory | Out-Null
        }
        
        write-text -type "done" -text "Folder created." -lineAfter
    } catch {
        write-text "Error creating temp folder: $($_.Exception.Message)" -type "error"
    }
}

