function isrInstallApps {
    try {
        $installChoice = readOption -options $([ordered]@{
                "All"              = "Install all the apps that an ISR will need."
                "Chrome"           = "Install Google Chrome"
                "Zoom"             = "Install Microsoft Zoom."
                "RingCentral"      = "Install RingCentral."
                "Cliq"             = "Install Cliq."
                "Revo Uninstaller" = "Install RevoUninstaller."
                "Acrobat"          = "Install Adobe Acrobat reader."
                "Balto"            = "Install Balto AI"
                "Exit"             = "Exit this script and go back to main command line."
            }) -prompt "Select which apps to install:"

        if ($installChoice -ne 8) { 
            $script:user = selectUser -prompt "Select user to install apps for:"
        }
        if ($installChoice -eq 1 -or $installChoice -eq 0) { 
            install-chrome 
        }
        if ($installChoice -eq 2 -or $installChoice -eq 0) { 
            install-zoom
        }
        if ($installChoice -eq 3 -or $installChoice -eq 0) { 
            install-ringcentral
        }
        if ($installChoice -eq 4 -or $installChoice -eq 0) { 
            install-Cliq
        }
        if ($installChoice -eq 5 -or $installChoice -eq 0) { 
            install-revouninstaller
        }
        if ($installChoice -eq 6 -or $installChoice -eq 0) { 
            install-acrobatreader
        }
        if ($installChoice -eq 7 -or $installChoice -eq 0) { 
            install-balto
        }
        if ($installChoice -eq 8) { 
            readCommand
        }

        Initialize-Cleanup
    } catch {
        # Display error message and end the script
        writeText -type "error" -text "isrInstallApps-$($_.InvocationInfo.ScriptLineNumber) | $($_.Exception.Message)" -lineAfter
    }
}
function install-chrome {
    $paths = @(
        "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
        "$env:ProgramFiles (x86)\Google\Chrome\Application\chrome.exe",
        "C:\Users\$($user["Name"])\AppData\Google\Chrome\Application\chrome.exe"
    )

    $url = "https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi"
    $appName = "Google Chrome"
    $installed = Find-ExistingInstall -Paths $paths -App $appName
    if (!$installed) { 
        Install-Program $url $appName "msi" "/qn" 
    }

    $bookmarksChoice = readOption -options $([ordered]@{
            "Install bookmarks" = "Add ISR bookmarks to Google Chrome now."
            "Skip"              = "Skip ahead and do not add bookmarks to Google Chrome."
        }) -prompt "Do you want to install ISR bookmarks for Chrome?" -lineBefore

    if ($bookmarksChoice -eq 0) { 
        isrAddBookmarks
    }
}
function isrAddBookmarks {
    try {
        $profiles = [ordered]@{}
        $chromeUserDataPath = "C:\Users\$($user["Name"])\AppData\Local\Google\Chrome\User Data"
        if (!(Test-Path $chromeUserDataPath)) {
            # throw "No user directory. It's likely the account has not had it's first sign-in yet." 
            New-Item -ItemType Directory -Path $chromeUserDataPath
        }
        $profileFolders = Get-ChildItem -Path $chromeUserDataPath -Directory
        if ($null -eq $profileFolders) { 
            New-Item -ItemType Directory -Path "$chromeUserDataPath\Default" -Force
        }
        foreach ($profileFolder in $profileFolders) {
            $preferencesFile = Join-Path -Path $profileFolder.FullName -ChildPath "Preferences"
            if (Test-Path -Path $preferencesFile) {
                $preferencesContent = Get-Content -Path $preferencesFile -Raw | ConvertFrom-Json
                $profileName = $preferencesContent.account_info.email
                if ($null -eq $preferencesContent.account_info.email) {
                    $profileName = $preferencesContent.account_info.account_id
                } 
                $profiles["$profileName"] = $profileFolder.FullName
            }
        }

        $choice = readOption -options $profiles -prompt "Select a Chrome profile:" -ReturnKey 
        $account = $profiles["$choice"]
        $boomarksurl = "https://drive.google.com/uc?export=download&id=1WmvSnxtDSLOt0rgys947sOWW-v9rzj9U"

        $download = getDownload -url $boomarksurl -target "$env:SystemRoot\Temp\Bookmarks"
        if ($download) { 
            

            ROBOCOPY $env:SystemRoot\Temp $account "Bookmarks" /NFL /NDL /NC /NS /NP | Out-Null

            Remove-Item -Path "$env:SystemRoot\Temp\Bookmarks" -Force

            $preferencesFilePath = Join-Path -Path $profiles["$choice"] -ChildPath "Preferences"
            if (Test-Path -Path $preferencesFilePath) {
                $preferences = Get-Content -Path $preferencesFilePath -Raw | ConvertFrom-Json
                if (-not $preferences.PSObject.Properties.Match('bookmark_bar').Count) {
                    $preferences | Add-Member -type NoteProperty -Name 'bookmark_bar' -Value @{}
                }

                if (-not $preferences.bookmark_bar.PSObject.Properties.Match('show_on_all_tabs').Count) {
                    $preferences.bookmark_bar | Add-Member -type NoteProperty -Name 'show_on_all_tabs' -Value $true
                } else {
                    $preferences.bookmark_bar.show_on_all_tabs = $true
                }

                $preferences | ConvertTo-Json -Depth 100 | Set-Content -Path $preferencesFilePath
            } else {
                throw "Preferences file not found."
            }

            if (Test-Path -Path $account) {
                writeText -type "success" -text "The bookmarks have been added."
            }
        }
    } catch {
        # Display error message and end the script
        writeText -type "error" -text "isrAddBookmarks-$($_.InvocationInfo.ScriptLineNumber) | $($_.Exception.Message)"
    }
}
function install-cliq {
    $paths = @(
        "C:\Program Files (x86)\Cliq Deployment\cliqDeploymentTool.exe"
    )
    $url = "https://downloads.zohocdn.com/chat-desktop/windows/Cliq-1.7.3-x64.msi"
    $appName = "Cliq"
    $installed = Find-ExistingInstall -Paths $paths -App $appName
    if (!$installed) { 
        Install-Program $url $appName "msi" "/qn" 
    }
}
function install-zoom {
    $paths = @(
        "C:\Program Files\Zoom\Zoom.exe",
        "C:\Program Files\Zoom\bin\Zoom.exe",
        "C:\Users\$($user["Name"])\AppData\Zoom\Zoom.exe"
    )
    $url = "https://zoom.us/client/latest/ZoomInstallerFull.msi?archType=x64"
    $appName = "Zoom"
    $installed = Find-ExistingInstall -Paths $paths -App $appName
    if (!$installed) { 
        Install-Program $url $appName "msi" "/qn" 
    }
}
function install-ringcentral {
    $paths = @(
        "C:\Program Files\RingCentral\RingCentral.exe",
        "C:\Users\$env:username\AppData\Local\Programs\RingCentral"
    )
    $url = "https://app.ringcentral.com/download/squirrel-windows/RingCentral-Setup.msi"
    $appName = "Ring Central"
    $installed = Find-ExistingInstall -Paths $paths -App $appName
    if (!$installed) { 
        Install-Program $url $appName "msi" "/qn" 
    }
}
function install-revouninstaller {
    $paths = @("C:\Program Files\VS Revo Group\Revo Uninstaller\RevoUnin.exe")
    $url = "https://download.revouninstaller.com/download/revosetup.exe"
    $appName = "Revo Uninstaller"
    $installed = Find-ExistingInstall -Paths $paths -App $appName
    if (!$installed) { 
        Install-Program $url $appName "exe" "/verysilent" 
    }
}
function install-acrobatreader {
    $paths = @(
        "C:\Program Files\Adobe\Acrobat DC\Acrobat\Acrobat.exe"
        "C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe"
    )
    $url = "https://ardownload2.adobe.com/pub/adobe/reader/win/AcrobatDC/2300820555/AcroRdrDC2300820555_en_US.exe"
    $appName = "Adobe Acrobat Reader"
    $installed = Find-ExistingInstall -Paths $paths -App $appName
    if (!$installed) { 
        Install-Program $url $appName "exe" "/sAll /rs /msi EULA_ACCEPT=YES" 
    }
}
function install-balto {
    $paths = @("C:\Users\$($user["Name"])\AppData\Local\Programs\Balto\Balto.exe")
    $url = "https://download.baltocloud.com/Balto+Setup+6.3.0.exe"
    $appName = "Balto"
    $installed = Find-ExistingInstall -Paths $paths -App $appName
    if (!$installed) { 
        Install-Program $url $appName "exe" "/silent" 
    }
}
function Initialize-Cleanup {
    Remove-Item "$env:SystemRoot\Temp\Revo Uninstaller.lnk" -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\Users\Public\Desktop\Revo Uninstaller.lnk" -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:SystemRoot\Temp\Adobe Acrobat.lnk" -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\Users\Public\Desktop\Adobe Acrobat.lnk" -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:SystemRoot\Temp\Microsoft Edge.lnk" -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\Users\Public\Desktop\Microsoft Edge.lnk" -Force -ErrorAction SilentlyContinue
}
function Find-ExistingInstall {
    param (
        [parameter(Mandatory = $true)]
        [array]$Paths,
        [parameter(Mandatory = $true)]
        [string]$App
    )

    writeText -type "notice" -text "Installing $App" -lineBefore

    $installationFound = $false

    foreach ($path in $paths) {
        if (Test-Path $path) {
            $installationFound = $true
            break
        }
    }

    if ($installationFound) { 
        writeText -type "success" -text "$App already installed."
    }

    return $installationFound
}
function Install-Program {
    param (
        [parameter(Mandatory = $true)]
        [string]$url,
        [parameter(Mandatory = $true)]
        [string]$AppName,
        [parameter(Mandatory = $true)]
        [string]$Extension,
        [parameter(Mandatory = $true)]
        [string]$Args
    )

    try {
        if ($Extension -eq "msi") {
            $output = "$AppName.msi"
        } else {
            $output = "$AppName.exe"
        }

        $download = getDownload -url $url -target "$env:SystemRoot\Temp\$output" 

        if ($download) {
            if ($Extension -eq "msi") {
                $process = Start-Process -FilePath "msiexec" -ArgumentList "/i `"$env:SystemRoot\Temp\$output`" $Args" -PassThru
            } else {
                $process = Start-Process -FilePath "$env:SystemRoot\Temp\$output" -ArgumentList "$Args" -PassThru
            }

            $curPos = $host.UI.RawUI.CursorPosition

            while (!$process.HasExited) {
                Write-Host -NoNewLine "`r  Installing |"
                Start-Sleep -Milliseconds 150
                Write-Host -NoNewLine "`r  Installing /"
                Start-Sleep -Milliseconds 150
                Write-Host -NoNewLine "`r  Installing $([char]0x2015)"
                Start-Sleep -Milliseconds 150
                Write-Host -NoNewLine "`r  Installing \"
                Start-Sleep -Milliseconds 150
            }

            # Restore the cursor position after the installation is complete
            [Console]::SetCursorPosition($curPos.X, $curPos.Y)

            $nextPos = $host.UI.RawUI.CursorPosition

            Write-Host "                                                     `r"

            [Console]::SetCursorPosition($nextPos.X, $nextPos.Y)

            Get-Item -ErrorAction SilentlyContinue "$env:SystemRoot\Temp\$output" | Remove-Item -ErrorAction SilentlyContinue

            writeText -type "success" -text "$AppName successfully installed."
        }        
    } catch {
        writeText -type "error" -text "Installation error: $($_.Exception.Message)"
        writeText "Skipping $AppName installation."
    }
}