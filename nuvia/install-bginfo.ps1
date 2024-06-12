function install-bginfo {
    try {
        # Check if the current PowerShell session is running as the system account
        if ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name -eq 'NT AUTHORITY\SYSTEM') {
            write-text -type "notice" -Text "RUNNING AS SYSTEM: Changes wont apply until reboot. Run as logged user for instant results." -lineBefore
        }
        
        Write-Host

        $url = "https://drive.google.com/uc?export=download&id=18gFWHawWknKufHXjcmMUB0SwGoSlbBEk" 
        $target = "Nuvia" 

        $download = get-download -Url $url -Target "$env:TEMP\$target`_BGInfo.zip" -visible
        if (!$download) { exit-script -type "error" -text "Couldn't download Bginfo." }

        # Set the wallpaper property
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name WallPaper -Value "" 

        # Set the background color property
        Set-ItemProperty -Path "HKCU:\Control Panel\Colors" -Name Background -Value "0 0 0" 

        # I don't know of a good way to check that this value has actually changed
        write-text -type "success" -text "Wallpaper successfully cleared." -lineBefore

        Expand-Archive -LiteralPath "$env:TEMP\$target`_BGInfo.zip" -DestinationPath "$env:TEMP\"

        # Test if the extracted folder exists
        if (Test-Path "$env:TEMP\BGInfo") {
            write-text -type "success" -text "BGInfo successfully unpacked."
        } else {
            write-text -type "error" -text "Failed to unpack BGInfo."
        }

        ROBOCOPY "$env:TEMP\BGInfo" "C:\Program Files\BGInfo" /E /NFL /NDL /NJH /NJS /nc /ns | Out-Null
        ROBOCOPY "$env:TEMP\BGInfo" "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup" "Start BGInfo.bat" /NFL /NDL /NJH /NJS /nc /ns | Out-Null

        if (Test-Path "C:\Program Files\BGInfo") {
            write-text -type "success" -text "BGInfo successfully installed."
        } else {
            write-text -type "error" -text "Failed to install BGInfo."
        }

        Remove-Item -Path "$env:TEMP\$target`_BGInfo.zip" -Recurse
        Remove-Item -Path "$env:TEMP\BGInfo" -Recurse 

        $filesDeleted = $true
        if (Test-Path "$env:TEMP\$target`_BGInfo.zip") { $filesDeleted = $false }
        if (Test-Path "$env:TEMP\BGInfo") { $filesDeleted = $false } 
        if ($filesDeleted) {
            write-text -type "success" -text "Temp files successfully deleted."
        } else {
            write-text -type "error" -text "Some temp files were not deleted. This is harmless."
        }

        Start-Process -FilePath "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\Start BGInfo.bat" -WindowStyle Hidden

        exit-script -type "success" -Text "BGInfo installed and applied." -lineAfter
    } catch {
        # Display error message and end the script
        exit-script -type "error" -text "install-bginfo-$($_.InvocationInfo.ScriptLineNumber) | $($_.Exception.Message)" -lineAfter
    }
}
