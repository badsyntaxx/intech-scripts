function uninstallNinjaRMM {
    try {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        if (-not $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) { 
            throw "This script must be ran as an admin."
        }

        writeText -type "plain" -text "Searching for NinjaRMMAgent in $env:ProgramFiles"
        $NinjaExe = ""
        $folders = Get-ChildItem "$env:ProgramFiles"
        foreach ($folder in $folders) {
            if (Test-Path -Path "$env:ProgramFiles\$folder") {
                if (Test-Path -Path "$env:ProgramFiles\$folder\NinjaRMMAgent.exe") {
                    writeText -type "notice" -text "Found NinjaRMMAgent at $env:ProgramFiles\$folder\NinjaRMMAgent.exe"
                    $NinjaExe = "$env:ProgramFiles\$folder\NinjaRMMAgent.exe";
                }
            }
        }

        writeText -type "plain" -text "Searching in $(${env:ProgramFiles(x86)})"
        $folders = Get-ChildItem "$(${env:ProgramFiles(x86)})"
        foreach ($folder in $folders) {
            if (Test-Path -Path "$(${env:ProgramFiles(x86)})\$folder") {
                if (Test-Path -Path "$(${env:ProgramFiles(x86)})\$folder\NinjaRMMAgent.exe") {
                    writeText -type "notice" -text "Found NinjaRMMAgent at $(${env:ProgramFiles(x86)})\$folder\NinjaRMMAgent.exe"
                    $NinjaExe = "$(${env:ProgramFiles(x86)})\$folder\NinjaRMMAgent.exe";
                }
            }
        }
    
        if ($NinjaExe -eq "") {
            throw "Couldn't Find the Ninja Agent."
        }

        writeText -type "plain" -text "Ninja Agent was Found, stopping service." 
        Stop-Service -Name NinjaRMMAgent -Force
        $service = Get-Service -Name NinjaRMMAgent
        While ($service.Status -eq "Running") {
            $service = Get-Service -Name NinjaRMMAgent
            writeText -type "notice" -text "Waiting for NinjaRMMAgent Service to Stop."
        }

        writeText -type "plain" -text "Executing $($NinjaExe) --disableUninstallPrevention" -lineAfter
        $process = Start-Process -FilePath "$($NinjaExe)" -ArgumentList "--disableUninstallPrevention" -Wait -PassThru -NoNewWindow
        writeText -type "plain" -text "Disable process exited with Exit Code: $($process.ExitCode)" -lineBefore

        if ($process.ExitCode -eq 0) {
            writeText -type "success" -text "Successfully disabled Uninstall Prevention." -lineAfter
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
    } catch {
        writeText -type "error" -text "uninstall-ninja-$($_.InvocationInfo.ScriptLineNumber) | $($_.Exception.Message)" -lineAfter
    }    
}