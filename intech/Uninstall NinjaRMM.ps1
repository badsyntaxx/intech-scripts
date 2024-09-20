function uninstallNinjaRMM {
    $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object System.Security.Principal.WindowsPrincipal($id)
    if ($p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) { 
        writeText -type "plain" -text "[x] Searching for NinjaRMMAgent(s)"
        writeText -type "plain" -text "Searching in $($env:ProgramFiles)"
        $NinjaExe = ""
        $folders = Get-ChildItem "$($env:ProgramFiles)"
        foreach ($folder in $folders) {
            if (Test-Path -Path "$($env:ProgramFiles)\$($folder)") {
                if (Test-Path -Path "$($env:ProgramFiles)\$($folder)\NinjaRMMAgent.exe") {
                    writeText -type "notice" -text "Found NinjaRMMAgent at $($env:ProgramFiles)\$($folder)\NinjaRMMAgent.exe"
                    $NinjaExe = "$($env:ProgramFiles)\$($folder)\NinjaRMMAgent.exe";
                }
            }
        }
        writeText -type "plain" -text "Searching in $(${env:ProgramFiles(x86)})"
        $folders = Get-ChildItem "$(${env:ProgramFiles(x86)})"
        foreach ($folder in $folders) {
            if (Test-Path -Path "$(${env:ProgramFiles(x86)})\$($folder)") {
                if (Test-Path -Path "$(${env:ProgramFiles(x86)})\$($folder)\NinjaRMMAgent.exe") {
                    writeText -type "notice" -text "Found NinjaRMMAgent at $(${env:ProgramFiles(x86)})\$($folder)\NinjaRMMAgent.exe"
                    $NinjaExe = "$(${env:ProgramFiles(x86)})\$($folder)\NinjaRMMAgent.exe";
                }
            }
        }
    
        if ($NinjaExe -ne "") {
            writeText -type "success" -text "Ninja Agent was Found, Continuing." 
            writeText -type "plain" -text "Validating the Ninja Agent Service is Stopped."
            Stop-Service -Name NinjaRMMAgent -Force
            $service = Get-Service -Name NinjaRMMAgent
            While ($service.Status -eq "Running") {
                $service = Get-Service -Name NinjaRMMAgent
                writeText -type "notice" -text "[o] Waiting for NinjaRMMAgent Service to Stop."
            }
            writeText -type "plain" -text "Executing $($NinjaExe) --disableUninstallPrevention"
            $process = Start-Process -FilePath "$($NinjaExe)" -ArgumentList "--disableUninstallPrevention" -Wait -PassThru -NoNewWindow
            writeText -type "plain" -text "Process exited with Exit Code: $($process.ExitCode)"
            if ($process.ExitCode -eq 0) {
                writeText -type "success" -text "Successfully disabled Uninstall Prevention." 
                writeText -type "plain" -text "Checking for Uninstaller."
                $Uninstaller = $NinjaExe.Replace("NinjaRMMAgent.exe", "uninstall.exe")
                if (Test-Path -Path $Uninstaller) {
                    writeText -type "notice" -text "Uninstaller Exists, Continuing."
                    $process = Start-Process -FilePath $Uninstaller -ArgumentList "--mode unattended" -Wait -PassThru -NoNewWindow
                    writeText -type "plain" -text "Uninstaller Exited with Code: $($process.ExitCode)"
                    if ($process.ExitCode -eq 0) {
                        writeText -type "success" -text "Uninstall was successful. Performing Cleanup." 
                        $NinjaDirectory = $NinjaExe.Replace("NinjaRMMAgent.exe", "")
                        writeText -type "plain" -text "Removing $($NinjaDirectory)"
                        Remove-Item $NinjaDirectory -Force -Recurse -ErrorAction SilentlyContinue
                        writeText -type "plain" -text "Removing $($env:ProgramData)\NinjaRMMAgent\"
                        Remove-Item "$($env:ProgramData)\NinjaRMMAgent\" -Force -Recurse -ErrorAction SilentlyContinue
                    } else {
                        writeText -type "error" -text "Uninstall failed."
                    }
                } else {
                    writeText -type "error" -text "Cant find uninstaller."
                }
            } else {
                writeText -type "error" -text "Couldn't disable Uninstall Prevention. Make sure the service actually stopped running."
            }
        } else {
            writeText -type "error" -text "Couldn't Find the Ninja Agent."
        }
    } else {
        writeText -type "error" -text "This script must be ran as an admin."
    }
}