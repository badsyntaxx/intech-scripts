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
        if ($download) {             
            $JumpCloudConnectKey = "fe8929df5bbccb8aceb58385b88aba034b7d69f7";
            msiexec /i $AGENT_INSTALLER_PATH /quiet JCINSTALLERARGUMENTS=`"-k $JumpCloudConnectKey /VERYSILENT /NORESTART /NOCLOSEAPPLICATIONS /L*V "C:\Windows\Temp\jcUpdate.log"`"

            $curPos = $host.UI.RawUI.CursorPosition

            while (!$process.HasExited) {
                $AgentService = Get-Service -Name "jumpcloud-agent" -ErrorAction SilentlyContinue
                if ($AgentService.Status -eq "Running") {
                    write-text -type "success" -text "`r$([char]0x2713) JumpCloud Agent Installed."
                    break
                } else {
                    Write-Host -NoNewLine "`r  Installing |"
                    Start-Sleep -Milliseconds 150
                    Write-Host -NoNewLine "`r  Installing /"
                    Start-Sleep -Milliseconds 150
                    Write-Host -NoNewLine "`r  Installing $([char]0x2015)"
                    Start-Sleep -Milliseconds 150
                    Write-Host -NoNewLine "`r  Installing \"
                    Start-Sleep -Milliseconds 150
                }
            }

            [Console]::SetCursorPosition($curPos.X, $curPos.Y)
        }
    } catch {
        write-text -type "error" -text "nuvia-install-jumpcloud-$($_.InvocationInfo.ScriptLineNumber) - $($_.Exception.Message)"
    }
}