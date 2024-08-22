# msiexec /i https://app.ninjarmm.com/agent/installer/0274c0c3-3ec8-44fc-93cb-79e96f191e07/nuvianuviacentralsupport-5.9.9652-windows-installer.msi /qb

# cd $env:temp | Invoke-Expression; Invoke-RestMethod -Method Get -URI https://raw.githubusercontent.com/TheJumpCloud/support/master/scripts/windows/InstallWindowsAgent.ps1 -OutFile InstallWindowsAgent.ps1 | Invoke-Expression; ./InstallWindowsAgent.ps1 -JumpCloudConnectKey "fe8929df5bbccb8aceb58385b88aba034b7d69f7"

function install-jumpcloud {
    try {
        # To run unattended pass in the parameter -JumpCloudConnectKey in when calling the InstallWindowsAgent.ps1
        # Example ./InstallWindowsAgent.ps1 -JumpCloudConnectKey "56b403784365r6o2n311cosr218u1762le4y9e9a"
        # Your JumpCloudConnectKey can be found on the systems tab within the JumpCloud admin console.

        #--- Modify Below This Line At Your Own Risk ------------------------------

        # JumpCloud Agent Installation Variables
        $JumpCloudConnectKey = "fe8929df5bbccb8aceb58385b88aba034b7d69f7";
        $AGENT_PATH = Join-Path ${env:ProgramFiles} "JumpCloud"
        $AGENT_BINARY_NAME = "jumpcloud-agent.exe"
        $AGENT_INSTALLER_URL = "https://cdn02.jumpcloud.com/production/jcagent-msi-signed.msi"
        $AGENT_INSTALLER_PATH = "$env:SystemRoot\Temp\jcagent-msi-signed.msi"
        # JumpCloud Agent Installation Functions
        Function InstallAgent() {
            msiexec /i $AGENT_INSTALLER_PATH /quiet JCINSTALLERARGUMENTS=`"-k $JumpCloudConnectKey /VERYSILENT /NORESTART /NOCLOSEAPPLICATIONS /L*V "C:\Windows\Temp\jcUpdate.log"`"
        }
        Function DownloadAgentInstaller() {
    (New-Object System.Net.WebClient).DownloadFile("${AGENT_INSTALLER_URL}", "${AGENT_INSTALLER_PATH}")
        }
        Function DownloadAndInstallAgent() {
            If (Test-Path -Path "$($AGENT_PATH)\$($AGENT_BINARY_NAME)") {
                write-text -type 'success' -text 'JumpCloud Agent Already Installed'
                read-command
            } else {
                write-text 'Downloading JCAgent Installer'
                # Download Installer
                DownloadAgentInstaller
                write-text 'JumpCloud Agent Download Complete'
                write-text 'Running JCAgent Installer'
                # Run Installer
                InstallAgent

                # Check if agent is running as a service
                # Do a loop for 5 minutes to check if the agent is running as a service
                # The agent pulls cef files during install which may take longer then previously.
                for ($i = 0; $i -lt 300; $i++) {
                    Start-Sleep -Seconds 1
                    #Output the errors encountered
                    $AgentService = Get-Service -Name "jumpcloud-agent" -ErrorAction SilentlyContinue
                    if ($AgentService.Status -eq 'Running') {
                        write-text 'JumpCloud Agent Succesfully Installed'
                        exit
                    }
                }
                write-text 'JumpCloud Agent Failed to Install'
            }
        }

        #Flush DNS Cache Before Install

        ipconfig /FlushDNS

        # JumpCloud Agent Installation Logic

        DownloadAndInstallAgent

        write-text -type "success" -text "JumpCloud successfully installed." -lineAfter
        read-command
    } catch {
        # Display error message and end the script
        write-text -type "error" -text "isr-install-ninja-$($_.InvocationInfo.ScriptLineNumber) - $($_.Exception.Message)"
        read-command
    }
}