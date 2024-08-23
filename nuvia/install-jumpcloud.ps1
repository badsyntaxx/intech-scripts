function install-jumpcloud {
    try {
        ipconfig /FlushDNS | Out-Null
        $AGENT_PATH = Join-Path ${env:ProgramFiles} "JumpCloud"
        $AGENT_BINARY_NAME = "jumpcloud-agent.exe"
        if (Test-Path -Path "$($AGENT_PATH)\$($AGENT_BINARY_NAME)") {
            write-text -type "success" -text "JumpCloud Agent Already Installed."
            read-command
        } 

        $AGENT_INSTALLER_URL = "https://cdn02.jumpcloud.com/production/jcagent-msi-signed.msi"
        $AGENT_INSTALLER_PATH = "$env:SystemRoot\Temp\jcagent-msi-signed.msi"
        
        $download = get-download -Url $AGENT_INSTALLER_URL -Target $AGENT_INSTALLER_PATH -visible
        if (!$download) { 
            throw "Unable to acquire intaller." 
        }
            
        $JumpCloudConnectKey = "fe8929df5bbccb8aceb58385b88aba034b7d69f7";
        msiexec /i $AGENT_INSTALLER_PATH /quiet JCINSTALLERARGUMENTS=`"-k $JumpCloudConnectKey /VERYSILENT /NORESTART /NOCLOSEAPPLICATIONS /L*V "C:\Windows\Temp\jcUpdate.log"`"

        $curPos = $host.UI.RawUI.CursorPosition
        $dots = ""
        $counter = 0
        while (!$process.HasExited) {
            if ($AgentService.Status -eq "Running") {
                write-text -type "success" -text "JumpCloud Agent Succesfully Installed"
            } else {
                Write-Host -NoNewLine "`r  Installing$dots"
                $dots += "."
                Start-Sleep -Milliseconds 100
                $counter++
                if ($counter -eq 7) {
                    $dots = ""
                    $counter = 0
                }

                # Clear the previous line before writing the new one
                Write-Host -NoNewLine "`r                                  " -ForegroundColor White
                Write-Host -NoNewLine "`r  Installing$dots" -ForegroundColor White
            }
        }

        # Restore the cursor position after the installation is complete
        [Console]::SetCursorPosition($curPos.X, $curPos.Y)
    } catch {
        # Display error message and end the script
        write-text -type "error" -text "nuvia-install-jumpcloud-$($_.InvocationInfo.ScriptLineNumber) - $($_.Exception.Message)"
    }
}