function uninstallNinjaRMM {
    try {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        if (-not $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) { 
            throw "This script requires administrator privileges."
        }

        $NinjaExe = findAgent
        if ($NinjaExe -eq "") {
            throw "Couldn't Find the Ninja Agent."
        }

        writeText -type "plain" -text "Attempting to disable uninstall prevention." -lineAfter
        $process = Start-Process -FilePath "$NinjaExe" -ArgumentList "-disableUninstallPrevention" -Wait -PassThru -NoNewWindow
        # writeText -type "plain" -text "Disable process exited with Exit Code: $($process.ExitCode)" -lineBefore

        if ($process.ExitCode -ne 0 -and $process.ExitCode -ne 1) {
            throw "Couldn't disable Uninstall Prevention. Make sure the service actually stopped running."
        }
        
        writeText -type "notice" -text "Uninstall prevention disabled."
        $NinjaDir = Split-Path -Parent $NinjaExe
        $Uninstaller = Join-Path $NinjaDir "uninstall.exe"

        if (Test-Path -Path $Uninstaller) {
            writeText -type "plain" -text "Uninstalling NinjaRMMAgent."
            $process = Start-Process -FilePath $Uninstaller -ArgumentList "--mode unattended" -Wait -PassThru -NoNewWindow
            # writeText -type "plain" -text "Uninstaller Exited with Code: $($process.ExitCode)"
            if ($process.ExitCode -ne 0) {
                throw "Uninstall failed. Exit code $($process.ExitCode)"
            }

            writeText -type "plain" -text "Uninstaller ran successful. Performing Cleanup." 
            $NinjaDirectory = Split-Path -Parent $NinjaExe
            writeText -type "plain" -text "Removing $($NinjaDirectory)"
            Remove-Item $NinjaDirectory -Force -Recurse -ErrorAction SilentlyContinue
            writeText -type "plain" -text "Removing $($env:ProgramData)\NinjaRMMAgent\"
            Remove-Item "$($env:ProgramData)\NinjaRMMAgent\" -Force -Recurse -ErrorAction SilentlyContinue

            writeText -type "plain" -text "Deleting registry keys."
            $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\NinjaRMMAgent"
            if (Test-Path $registryPath) {
                writeText -type "plain" -text "Removing registry key: $registryPath"
                Remove-Item -Path $registryPath -Force -ErrorAction SilentlyContinue
                if (Test-Path $registryPath) {
                    writeText -type "error" -text "Failed to remove registry key: $registryPath"
                } else {
                    writeText -type "success" -text "Successfully removed registry key: $registryPath"
                }
            } else {
                writeText -type "notice" -text "Registry key not found: $registryPath"
            }

            writeText -type "success" -text "NinjaRMM uninstalled." 
        } else {
            writeText -type "error" -text "Can't find uninstaller at $Uninstaller"
        }
        


    } catch {
        writeText -type "error" -text "uninstall-ninja-$($_.InvocationInfo.ScriptLineNumber) | $($_.Exception.Message)" -lineAfter
    }    
}

function findAgent {
    $searchPaths = @("$env:ProgramFiles", ${env:ProgramFiles(x86)})
    
    foreach ($path in $searchPaths) {
        $NinjaExe = Get-ChildItem -Path $path -Filter "NinjaRMMAgent.exe" -Recurse -ErrorAction SilentlyContinue |
        Select-Object -First 1 -ExpandProperty FullName
        
        if ($NinjaExe) {
            writeText -type "plain" -text "NinjaRMMAgent found at $NinjaExe"
            return $NinjaExe
        }
    }
    
    return ""
}