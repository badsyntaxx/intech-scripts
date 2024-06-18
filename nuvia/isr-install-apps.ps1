function isr-install-apps {
    try {
        $installChoice = read-option -options $([ordered]@{
                "All"              = "Install all the apps that an ISR will need."
                "Chrome"           = "Install Google Chrome."
                "Cliq"             = "Install Zoho Cliq."
                "Zoom"             = "Install Microsoft Zoom."
                "RingCentral"      = "Install RingCentral."
                "Revo Uninstaller" = "Install RevoUninstaller."
                "Acrobat"          = "Install Adobe Acrobat reader."
                "Balto"            = "Install Balto AI"
                "Explorer Patcher" = "Install ExplorerPatcher"
                "Exit"             = "Exit this script and go back to main command line."
            })

        $script:user = select-user -CustomHeader "Select user to install apps for"

        if ($installChoice -eq 1 -or $installChoice -eq 0) { install-chrome }
        if ($installChoice -eq 2 -or $installChoice -eq 0) { install-cliq }
        if ($installChoice -eq 3 -or $installChoice -eq 0) { install-zoom }
        if ($installChoice -eq 4 -or $installChoice -eq 0) { install-ringcentral }
        if ($installChoice -eq 5 -or $installChoice -eq 0) { install-revouninstaller }
        if ($installChoice -eq 6 -or $installChoice -eq 0) { install-acrobatreader }
        if ($installChoice -eq 7 -or $installChoice -eq 0) { install-balto }
        if ($installChoice -eq 8 -or $installChoice -eq 0) { 
            Install-ExplorerPatcher 
            Add-EPRegedits
        }
        if ($installChoice -eq 9) {
            read-command
        }

        Initialize-Cleanup
        exit-script
    } catch {
        # Display error message and end the script
        exit-script -type "error" -text "Error | Install-Apps-$($_.InvocationInfo.ScriptLineNumber)"
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
    if (!$installed) { Install-Program $url $appName "msi" "/qn" }
}

function Add-ChromeBookmarks {
    write-text -type "header" -text "Which profile "
    $profiles = [ordered]@{}
    $chromeUserDataPath = "C:\Users\$($user["name"])\AppData\Local\Google\Chrome\User Data"
    $profileFolders = Get-ChildItem -Path $chromeUserDataPath -Directory -ErrorAction SilentlyContinue
    if ($null -eq $profileFolders) { throw "Cannot find profiles for this Chrome installation." }
    foreach ($profileFolder in $profileFolders) {
        $preferencesFile = Join-Path -Path $profileFolder.FullName -ChildPath "Preferences"
        if (Test-Path -Path $preferencesFile) {
            $preferencesContent = Get-Content -Path $preferencesFile -Raw | ConvertFrom-Json
            $profileName = $preferencesContent.account_info.full_name
            $profiles["$profileName"] = $profileFolder.FullName
        }
    }

    $choice = read-option -options $profiles -lineAfter -ReturnKey
    $account = $profiles["$choice"]
    $boomarksUrl = "https://drive.google.com/uc?export=download&id=1WmvSnxtDSLOt0rgys947sOWW-v9rzj9U"

    $download = get-download -Url $boomarksUrl -Target "$env:TEMP\Bookmarks"
    if (!$download) { throw "Unable to acquire bookmarks." }

    ROBOCOPY $env:TEMP $account "Bookmarks" /NFL /NDL /NC /NS /NP | Out-Null

    Remove-Item -Path "$env:TEMP\Bookmarks" -Force

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
        exit-script -type "success" -text "The bookmarks have been added." -lineBefore
    }
}

function Install-Slack {
    $paths = @(
        "C:\Program Files\Slack\slack.exe",
        "C:\Users\$($user["Name"])\AppData\slack\slack.exe"
    )
    $url = "https://downloads.slack-edge.com/releases/windows/4.36.138/prod/x64/slack-standalone-4.36.138.0.msi"
    $appName = "Slack"
    $installed = Find-ExistingInstall -Paths $paths -App $appName
    if (!$installed) { Install-Program $url $appName "msi" "/qn" }
}

function install-cliq {
    $paths = @("C:\Users\$($user["Name"])\AppData\Local\cliq\app-1.7.1")
    $url = "https://downloads.zohocdn.com/chat-desktop/windows/Cliq_1.7.1_x64.exe"
    $appName = "Cliq"
    $installed = Find-ExistingInstall -Paths $paths -App $appName
    if (!$installed) { Install-Program $url $appName "exe" "/silent" }
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
    if (!$installed) { Install-Program $url $appName "msi" "/qn" }
}

function install-ringcentral {
    $paths = @(
        "C:\Program Files\RingCentral\RingCentral.exe",
        "C:\Users\$env:username\AppData\Local\Programs\RingCentral"
    )
    $url = "https://app.ringcentral.com/download/RingCentral-x64.msi"
    $appName = "Ring Central"
    $installed = Find-ExistingInstall -Paths $paths -App $appName
    if (!$installed) { Install-Program $url $appName "msi" "/qn" }
}

function install-revouninstaller {
    $paths = @("C:\Program Files\VS Revo Group\Revo Uninstaller\RevoUnin.exe")
    $url = "https://download.revouninstaller.com/download/revosetup.exe"
    $appName = "Revo Uninstaller"
    $installed = Find-ExistingInstall -Paths $paths -App $appName
    if (!$installed) { Install-Program $url $appName "exe" "/verysilent" }
}

function install-acrobatreader {
    $paths = @(
        "C:\Program Files\Adobe\Acrobat DC\Acrobat\Acrobat.exe"
        "C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe"
    )
    $url = "https://ardownload2.adobe.com/pub/adobe/reader/win/AcrobatDC/2300820555/AcroRdrDC2300820555_en_US.exe"
    $appName = "Adobe Acrobat Reader"
    $installed = Find-ExistingInstall -Paths $paths -App $appName
    if (!$installed) { Install-Program $url $appName "exe" "/sAll /rs /msi EULA_ACCEPT=YES" }
}

function install-balto {
    $paths = @("C:\Users\$($user["Name"])\AppData\Local\Programs\Balto\Balto.exe")
    $url = "https://download.baltocloud.com/Balto+Setup+6.1.1.exe"
    $appName = "Balto"
    $installed = Find-ExistingInstall -Paths $paths -App $appName
    if (!$installed) { Install-Program $url $appName "exe" "/silent" }
}

function Install-ExplorerPatcher {
    $paths = @("C:\Program Files\ExplorerPatcher\ep_gui.dll")
    $url = "https://github.com/valinet/ExplorerPatcher/releases/download/22621.2861.62.2_9b68cc0/ep_setup.exe"
    $appName = "ExplorerPatcher"
    $installed = Find-ExistingInstall -Paths $paths -App $appName
    if (!$installed) { Install-Program $url $appName "exe" "/silent" }
}

function Initialize-Cleanup {
    Remove-Item "$env:TEMP\Revo Uninstaller.lnk" -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\Users\Public\Desktop\Revo Uninstaller.lnk" -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:TEMP\Adobe Acrobat.lnk" -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\Users\Public\Desktop\Adobe Acrobat.lnk" -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:TEMP\Microsoft Edge.lnk" -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\Users\Public\Desktop\Microsoft Edge.lnk" -Force -ErrorAction SilentlyContinue
}

function Add-EPRegedits {
    Set-ItemProperty -Path "HKCU:\Software\ExplorerPatcher" -Name "ImportOK" -Value 1 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\ExplorerPatcher" -Name "OldTaskbar" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\ExplorerPatcher" -Name "Virtualized_{D17F1E1A-5919-4427-8F89-A1A8503CA3EB}_AutoHideTaskbar" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\ExplorerPatcher" -Name "SkinMenus" -Value 1 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\ExplorerPatcher" -Name "CenterMenus" -Value 1 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\ExplorerPatcher" -Name "FlyoutMenus" -Value 1 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\TabletTip\1.7" -Name "TipbandDesiredVisibility" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\ExplorerPatcher" -Name "HideControlCenterButton" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarSD" -Value 1 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\ExplorerPatcher" -Name "Virtualized_{D17F1E1A-5919-4427-8F89-A1A8503CA3EB}_RegisterAsShellExtension" -Value 1 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" -Name "(Default)" -Value "" -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\ExplorerPatcher" -Name "LegacyFileTransferDialog" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\ExplorerPatcher" -Name "UseClassicDriveGrouping" -Value 1 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\ExplorerPatcher" -Name "Virtualized_{D17F1E1A-5919-4427-8F89-A1A8503CA3EB}_FileExplorerCommandUI" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\ExplorerPatcher" -Name "DisableImmersiveContextMenu" -Value 0 -ErrorAction SilentlyContinue
    # Remove registry key
    Remove-Item -Path "HKCU:\Software\Classes\CLSID\{056440FD-8568-48e7-A632-72157243B55B}\InprocServer32" -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\ExplorerPatcher" -Name "Virtualized_{D17F1E1A-5919-4427-8F89-A1A8503CA3EB}_DisableModernSearchBar" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\ExplorerPatcher" -Name "ShrinkExplorerAddressBar" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\ExplorerPatcher" -Name "HideExplorerSearchBar" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\ExplorerPatcher" -Name "MicaEffectOnTitlebar" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_ShowClassicMode" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\ExplorerPatcher" -Name "Virtualized_{D17F1E1A-5919-4427-8F89-A1A8503CA3EB}_Start_MaximumFrequentApps" -Value 10 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartPage" -Name "MonitorOverride" -Value 1 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\ExplorerPatcher" -Name "Virtualized_{D17F1E1A-5919-4427-8F89-A1A8503CA3EB}_StartDocked_DisableRecommendedSection" -Value 1 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartPage" -Name "MakeAllAppsDefault" -Value 1 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "AltTabSettings" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\ExplorerPatcher" -Name "SpotlightDisableIcon" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\ExplorerPatcher" -Name "SpotlightDesktopMenuMask" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\ExplorerPatcher" -Name "SpotlightUpdateSchedule" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\ExplorerPatcher" -Name "LastSectionInProperties" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\ExplorerPatcher" -Name "ClockFlyoutOnWinC" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\ExplorerPatcher" -Name "ToolbarSeparators" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\ExplorerPatcher" -Name "PropertiesInWinX" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\ExplorerPatcher" -Name "NoMenuAccelerator" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\ExplorerPatcher" -Name "DisableOfficeHotkeys" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\ExplorerPatcher" -Name "DisableWinFHotkey" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\ExplorerPatcher" -Name "Virtualized_{D17F1E1A-5919-4427-8F89-A1A8503CA3EB}_DisableRoundedCorners" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\ExplorerPatcher" -Name "DisableAeroSnapQuadrants" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_PowerButtonAction" -Value 2 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\ExplorerPatcher" -Name "DoNotRedirectSystemToSettingsApp" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\ExplorerPatcher" -Name "DoNotRedirectProgramsAndFeaturesToSettingsApp" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\ExplorerPatcher" -Name "DoNotRedirectDateAndTimeToSettingsApp" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\ExplorerPatcher" -Name "DoNotRedirectNotificationIconsToSettingsApp" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\ExplorerPatcher" -Name "UpdatePolicy" -Value 1 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\ExplorerPatcher" -Name "UpdatePreferStaging" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\ExplorerPatcher" -Name "UpdateAllowDowngrades" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\ExplorerPatcher" -Name "UpdateURL" -Value "" -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\ExplorerPatcher" -Name "UpdateURLStaging" -Value "" -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\ExplorerPatcher" -Name "AllocConsole" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\ExplorerPatcher" -Name "Memcheck" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\ExplorerPatcher" -Name "TaskbarAutohideOnDoubleClick" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "PaintDesktopVersion" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\ExplorerPatcher" -Name "ClassicThemeMitigations" -Value 0 -ErrorAction SilentlyContinue
    # Remove registry key
    Remove-Item -Path "HKCU:\Software\Classes\CLSID\{1eeb5b5a-06fb-4732-96b3-975c0194eb39}\InprocServer32" -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\ExplorerPatcher" -Name "NoPropertiesInContextMenu" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\ExplorerPatcher" -Name "EnableSymbolDownload" -Value 1 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\ExplorerPatcher" -Name "ExplorerReadyDelay" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ExplorerPatcher" -Name "XamlSounds" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\ExplorerPatcher" -Name "Language" -Value 0 -ErrorAction SilentlyContinue

    write-text "Explorer configured" -type "done" -lineAfter
}

function Find-ExistingInstall {
    param (
        [parameter(Mandatory = $true)]
        [array]$Paths,
        [parameter(Mandatory = $true)]
        [string]$App
    )

    write-text -type "header" -text "Installing $App" -lineAfter

    $installationFound = $false

    foreach ($path in $paths) {
        if (Test-Path $path) {
            $installationFound = $true
            break
        }
    }

    if ($installationFound) { write-text -type "success" -text "$App already installed." -lineAfter }

    return $installationFound
}

function Install-Program {
    param (
        [parameter(Mandatory = $true)]
        [string]$Url,
        [parameter(Mandatory = $true)]
        [string]$AppName,
        [parameter(Mandatory = $true)]
        [string]$Extenstion,
        [parameter(Mandatory = $true)]
        [string]$Args
    )

    try {
        if ($Extenstion -eq "msi") { $output = "$AppName.msi" } else { $output = "$AppName.exe" }
        
        $download = get-download -Url $Url -Target "$env:TEMP\$output"

        if ($download) {
            if ($Extenstion -eq "msi") {
                $process = Start-Process -FilePath "msiexec" -ArgumentList "/i `"$env:TEMP\$output`" $Args" -PassThru
            } else {
                $process = Start-Process -FilePath "$env:TEMP\$output" -ArgumentList "$Args" -PassThru
            }

            $dots = ""
            $counter = 0
            while (!$process.HasExited) {
                $dots += "."
                Write-Host -NoNewLine "`r    Installing$dots    "
                Start-Sleep -Milliseconds 500
                $counter++
                if ($counter -eq 5) { 
                    $dots = "" 
                    $counter = 0
                }
            }

            Get-Item -ErrorAction SilentlyContinue "$env:TEMP\$output" | Remove-Item -ErrorAction SilentlyContinue
            
            write-text -type "success" -text "$AppName successfully installed." -lineBefore -lineAfter
        } else {
            write-text -type "error" -text "Download failed. Skipping." -lineAfter
        }
    } catch {
        write-text -type "error" -text "Installation error: $($_.Exception.Message)"
        write-text "Skipping $AppName installation."
    }
}

