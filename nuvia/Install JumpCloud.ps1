function installJumpCloud {
    try {
        & "C:\Windows\System32\cmd.exe" /c ipconfig /FlushDNS | Out-Null
        $AGENT_PATH = Join-Path ${env:ProgramFiles} "JumpCloud"
        $AGENT_BINARY_NAME = "jumpcloud-agent.exe"
        if (-not (Test-Path -Path "$($AGENT_PATH)\$($AGENT_BINARY_NAME)")) {
            $AGENT_INSTALLER_url = "https://cdn02.jumpcloud.com/production/jcagent-msi-signed.msi"
            $AGENT_INSTALLER_PATH = "$env:SystemRoot\Temp\jcagent-msi-signed.msi"
        
            $download = getDownload -url $AGENT_INSTALLER_url -target $AGENT_INSTALLER_PATH -lineBefore
            if ($download) {             
                $JumpCloudConnectKey = "fe8929df5bbccb8aceb58385b88aba034b7d69f7";
                & "C:\Windows\System32\cmd.exe" /c msiexec /i $AGENT_INSTALLER_PATH /quiet JCINSTALLERARGUMENTS=`"-k $JumpCloudConnectKey /VERYSILENT /NORESTART /NOCLOSEAPPLICATIONS /L*V "C:\Windows\Temp\jcUpdate.log"`"

                $curPos = $host.UI.RawUI.CursorPosition

                while (!$process.HasExited) {
                    $AgentService = Get-Service -Name "jumpcloud-agent" -ErrorAction SilentlyContinue
                    if ($AgentService.Status -eq "Running") {
                        writeText -type "success" -text "JumpCloud Agent Installed."
                        Write-Host
                        Write-Host
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

                Write-Host "                                                     `r"
                Write-Host
                Write-Host
            }
        } else {
            writeText -type "success" -text "JumpCloud Agent Already Installed."
        }
    } catch {
        writeText -type "error" -text "installJumpCloud-$($_.InvocationInfo.ScriptLineNumber) - $($_.Exception.Message)"
    }
}