function uninstallNinjaRMM {
    removeNinjaService -service "NinjaRMMAgent"
    removeNinjaService -service "ncstreamer"
    removeProgram
}

function removeNinjaService {
    param (
        [parameter(Mandatory = $true)]
        [string]$service
    ) 

    if (Get-Service -Name $service -ErrorAction SilentlyContinue) {
        & "C:\Windows\System32\cmd.exe" net stop $service
        & "C:\Windows\System32\cmd.exe" sc delete $service
    }
}

function removeProgram {
    $ninjaRMMDir = Get-ChildItem -Path "C:\Program Files (x86)" -Recurse -Filter "NinjaRMMAgent.exe" |
    Select-Object -ExpandProperty DirectoryName -First 1

    if ($ninjaRMMDir) {
        $uninstallerPath = Join-Path $ninjaRMMDir "NinjaRMMAgent.exe"

        write-text -type "plain" -text "Attempting to uninstall from: $uninstallerPath"
        Start-Process -FilePath $uninstallerPath -ArgumentList "/uninstall" -Wait -NoNewWindow

        write-text -type "plain" -text "Uninstallation process completed."

        # Remove the registry key
        $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\NinjaRMMAgent*"
        $registryKeys = Get-ChildItem -Path $registryPath -ErrorAction SilentlyContinue

        if ($registryKeys) {
            foreach ($key in $registryKeys) {
                write-text -type "plain" -text "Removing registry key: $($key.Name)"
                Remove-Item -Path $key.PSPath -Recurse -Force
            }
            write-text -type "plain" -text "Registry entries removed."
        } else {
            write-text -type "plain" -text "No matching registry entries found."
        }
    } else {
        write-text -type "plain" -text "NinjaRMMAgent.exe not found in C:\Program Files (x86)."
    }
}