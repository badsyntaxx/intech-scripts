function uninstallNinjaRMM {
    try {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        if (-not $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) { 
            throw "This script requires administrator privileges."
        }

        writeText -type "plain" -text "Searching for NinjaRMMAgent"

        $NinjaExe = findAgent
    
        if ($NinjaExe -eq "") {
            throw "Couldn't Find the Ninja Agent."
        }

        writeText -type "plain" -text "Executing $NinjaExe --disableUninstallPrevention" -lineAfter
        $process = Start-Process -FilePath "$NinjaExe" -ArgumentList "-disableUninstallPrevention" -Wait -PassThru -NoNewWindow
        writeText -type "plain" -text "Disable process exited with Exit Code: $($process.ExitCode)" -lineBefore

        <# if ($process.ExitCode -ne 0) {
            throw "Couldn't disable Uninstall Prevention. Make sure the service actually stopped running."
        } #>
        
        writeText -type "success" -text "Successfully disabled Uninstall Prevention." -lineAfter
        writeText -type "plain" -text "NinjaExe path: $NinjaExe"
        $NinjaDir = Split-Path -Parent $NinjaExe
        $Uninstaller = Join-Path $NinjaDir "uninstall.exe"
        writeText -type "plain" -text "Uninstaller path: $Uninstaller"

        if (Test-Path -Path $Uninstaller) {
            writeText -type "notice" -text "Uninstaller Exists, Continuing."
            $process = Start-Process -FilePath $Uninstaller -ArgumentList "--mode unattended" -Wait -PassThru -NoNewWindow
            writeText -type "plain" -text "Uninstaller Exited with Code: $($process.ExitCode)"
            if ($process.ExitCode -ne 0) {
                writeText -type "error" -text "Uninstall failed."
            }

            writeText -type "success" -text "Uninstall was successful. Performing Cleanup." 
            $NinjaDirectory = Split-Path -Parent $NinjaExe
            writeText -type "plain" -text "Removing $($NinjaDirectory)"
            Remove-Item $NinjaDirectory -Force -Recurse -ErrorAction SilentlyContinue
            writeText -type "plain" -text "Removing $($env:ProgramData)\NinjaRMMAgent\"
            Remove-Item "$($env:ProgramData)\NinjaRMMAgent\" -Force -Recurse -ErrorAction SilentlyContinue

            # Add registry key deletion
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

            writeText -type "success" -text "Full uninstall successful." 
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
            writeText -type "notice" -text "Found NinjaRMMAgent at $NinjaExe"
            return $NinjaExe
        }
    }
    
    return ""
}