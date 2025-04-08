function installJumpCloud {
    try {
        & "C:\Windows\System32\cmd.exe" /c ipconfig /FlushDNS | Out-Null
        $AGENT_PATH = Join-Path ${env:ProgramFiles} "JumpCloud"
        $AGENT_BINARY_NAME = "jumpcloud-agent.exe"
        if (-not (Test-Path -Path "$($AGENT_PATH)\$($AGENT_BINARY_NAME)")) {
            $AGENT_INSTALLER_url = "https://cdn02.jumpcloud.com/production/versions/2.23.0/jcagent-msi-signed.msi"
            $AGENT_INSTALLER_PATH = "$env:SystemRoot\Temp\jcagent-msi-signed.msi"
        
            $download = getDownload -url $AGENT_INSTALLER_url -target $AGENT_INSTALLER_PATH -lineBefore
            if ($download) {        
                $LOG_FILE = "$env:SystemRoot\Temp\jcInstall.log";
                $JumpCloudConnectKey = "30f0dbe3ccdc563f1426f4138f2b9046cdc44dbd";
                
                # Correct MSIEXEC arguments - note the proper quoting
                $installArgs = @(
                    "/i",
                    "`"$AGENT_INSTALLER_PATH`"",
                    "/quiet",
                    "/norestart",
                    "/L*V",
                    "`"$INSTALLER_LOG`"",
                    "JCINSTALLERARGUMENTS=`"-k $JumpCloudConnectKey /VERYSILENT /NORESTART /NOCLOSEAPPLICATIONS`""
                )
                
                "Starting installation with arguments: msiexec $installArgs" | Out-File -FilePath $LOG_FILE -Append
                
                $process = Start-Process -FilePath "msiexec" -ArgumentList $installArgs -PassThru -NoNewWindow -Wait

                writeText -type "plain" -text "[INFO] Installation process started (PID: $($process.Id))"
                writeText -type "plain" -text "[INFO] Waiting for agent service to start..."
                
                $startTime = Get-Date
                $timeout = New-TimeSpan -Minutes 5
                $animationChars = @('|', '/', '-', '\')
                $counter = 0

                while ((Get-Date) - $startTime -lt $timeout) {
                    $AgentService = Get-Service -Name "jumpcloud-agent" -ErrorAction SilentlyContinue
                    
                    if ($AgentService -and $AgentService.Status -eq "Running") {
                        Write-Host "`r[SUCCESS] JumpCloud Agent installed and running successfully!" -ForegroundColor Green
                        Write-Host "[INFO] Installation completed in: $((Get-Date) - $startTime)" -ForegroundColor Gray
                        Write-Host "[INFO] Service status: $($AgentService.Status)" -ForegroundColor Gray
                        Write-Host "[INFO] Service startup type: $($AgentService.StartType)" -ForegroundColor Gray
                        break
                    }
                    
                    # Animated progress indicator
                    $animation = $animationChars[$counter % $animationChars.Length]
                    Write-Host -NoNewline "`r[STATUS] Installing $animation (Elapsed: $((Get-Date) - $startTime))"
                    $counter++
                    Start-Sleep -Milliseconds 250
                }
                
                if (-not $AgentService -or $AgentService.Status -ne "Running") {
                    Write-Host "`r[WARNING] Installation timeout reached. Checking service status..." -ForegroundColor Yellow
                    $AgentService = Get-Service -Name "jumpcloud-agent" -ErrorAction SilentlyContinue
                    if (-not $AgentService) {
                        Write-Host "[ERROR] JumpCloud service not found after installation attempt." -ForegroundColor Red
                    } else {
                        Write-Host "[WARNING] JumpCloud service found but not running. Current status: $($AgentService.Status)" -ForegroundColor Yellow
                    }
                    Write-Host "[INFO] Please check the installation log at: $LOG_FILE" -ForegroundColor Gray
                }
                
                <# Write-Host "[INFO] Cleaning up installer..." -ForegroundColor Gray
                if (Test-Path $AGENT_INSTALLER_PATH) {
                    Remove-Item $AGENT_INSTALLER_PATH -Force
                    Write-Host "[INFO] Installer removed successfully." -ForegroundColor Gray
                } #>
            }
        } else {
            writeText -type "success" -text "JumpCloud Agent Already Installed."
        }
    } catch {
        writeText -type "error" -text "installJumpCloud-$($_.InvocationInfo.ScriptLineNumber) - $($_.Exception.Message)"
    }
}