function uninstallNinjaRMM {
    $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object System.Security.Principal.WindowsPrincipal($id)
    if ($p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) { 
        Write-Host "[x] Searching for NinjaRMMAgent(s)" -Fore Cyan
        Write-Host "[-] Searching in $($env:ProgramFiles)"
        $NinjaExe = ""
        $folders = Get-ChildItem "$($env:ProgramFiles)"
        foreach ( $folder in $folders ){
            if ( Test-Path -Path "$($env:ProgramFiles)\$($folder)" ){
                if ( Test-Path -Path "$($env:ProgramFiles)\$($folder)\NinjaRMMAgent.exe" ){
                    Write-Host "[-] Found NinjaRMMAgent at $($env:ProgramFiles)\$($folder)\NinjaRMMAgent.exe" -Fore Yellow
                    $NinjaExe = "$($env:ProgramFiles)\$($folder)\NinjaRMMAgent.exe";
                }
            }
        }
        Write-Host "[-] Searching in $(${env:ProgramFiles(x86)})"
        $folders = Get-ChildItem "$(${env:ProgramFiles(x86)})"
        foreach ( $folder in $folders ){
            if ( Test-Path -Path "$(${env:ProgramFiles(x86)})\$($folder)" ){
                if ( Test-Path -Path "$(${env:ProgramFiles(x86)})\$($folder)\NinjaRMMAgent.exe" ){
                    Write-Host "[-] Found NinjaRMMAgent at $(${env:ProgramFiles(x86)})\$($folder)\NinjaRMMAgent.exe" -Fore Yellow
                    $NinjaExe = "$(${env:ProgramFiles(x86)})\$($folder)\NinjaRMMAgent.exe";
                }
            }
        }
    
        if ( $NinjaExe -ne "" ){
            Write-Host "[-] Ninja Agent was Found, Continuing." -Fore Green
            Write-Host "[-] Validating the Ninja Agent Service is Stopped."
            Stop-Service -Name NinjaRMMAgent -Force
            $service = Get-Service -Name NinjaRMMAgent
            While ( $service.Status -eq "Running" ){
                $service = Get-Service -Name NinjaRMMAgent
                Write-Host "[o] Waiting for NinjaRMMAgent Service to Stop." -Fore Yellow
            }
            Write-Host "[-] Executing $($NinjaExe) --disableUninstallPrevention"
            $process = Start-Process -FilePath "$($NinjaExe)" -ArgumentList "--disableUninstallPrevention" -Wait -PassThru -NoNewWindow
            Write-Host "[-] Process exited with Exit Code: $($process.ExitCode)"
            if ( $process.ExitCode -eq 0 ){
                Write-Host "[-] Successfully disabled Uninstall Prevention." -Fore Green
                Write-Host "[-] Checking for Uninstaller."
                $Uninstaller = $NinjaExe.Replace("NinjaRMMAgent.exe", "uninstall.exe")
                if ( Test-Path -Path $Uninstaller ){
                    Write-Host "[-] Uninstaller Exists, Continuing." -Fore Yellow
                    $process = Start-Process -FilePath $Uninstaller -ArgumentList "--mode unattended" -Wait -PassThru -NoNewWindow
                    Write-Host "[-] Uninstaller Exited with Code: $($process.ExitCode)"
                    if ( $process.ExitCode -eq 0 ){
                        Write-Host "[-] Uninstall was successful. Performing Cleanup." -Fore Green
                        $NinjaDirectory = $NinjaExe.Replace("NinjaRMMAgent.exe", "")
                        Write-Host "[-] Removing $($NinjaDirectory)"
                        Remove-Item $NinjaDirectory -Force -Recurse -ErrorAction SilentlyContinue
                        Write-Host "[-] Removing $($env:ProgramData)\NinjaRMMAgent\"
                        Remove-Item "$($env:ProgramData)\NinjaRMMAgent\" -Force -Recurse -ErrorAction SilentlyContinue
                    } else {
                        Write-Host "[!] Uninstall failed." -Fore Red
                    }
                }
            } else {
                Write-Host "[-] Couldn't disable Uninstall Prevention. Make sure the service actually stopped running." -Fore Red
            }
        } else {
            Write-Host "[!] Couldn't Find the Ninja Agent." -Fore Red
        }
    } else {
        Write-Host "[!] This script must be ran as an admin." -Fore Red
    }
}