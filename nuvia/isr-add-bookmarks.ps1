function isr-add-bookmarks {
    try {
        $user = select-user -prompt "Select user to add bookmarks for:"
        $chromeUserDataPath = getOrCreateUserPath -username $user["Name"]
        $profiles = getChromeProfiles -userPath $chromeUserDataPath
        $choice = read-option -options $profiles -prompt "Select a Chrome profile:" -ReturnKey 
        $chromeProfile = $profiles["$choice"]
        $boomarksUrl = "https://drive.google.com/uc?export=download&id=1WmvSnxtDSLOt0rgys947sOWW-v9rzj9U"

        get-download -Url $boomarksUrl -Target "$env:SystemRoot\Temp\Bookmarks"
        ROBOCOPY $env:SystemRoot\Temp $chromeProfile "Bookmarks" /NFL /NDL /NC /NS /NP | Out-Null
        Remove-Item -Path "$env:SystemRoot\Temp\Bookmarks" -Force

        updateChromePreferences -profile $chromeProfile

        if (Test-Path -Path $chromeProfile) {
            write-text -type "success" -text "The bookmarks have been added."
        }
    } catch {
        write-text -type "error" -text "isr-add-bookmarks-$($_.InvocationInfo.ScriptLineNumber) | $($_.Exception.Message)"
    }
}
function getOrCreateUserPath {
    param (
        [Parameter(Mandatory = $true)]
        [string]$username
    )

    $chromeUserDataPath = "C:\Users\$($user["Name"])\AppData\Local\Google\Chrome\User Data"
    if (!(Test-Path $chromeUserDataPath)) {
        # throw "No user directory. It's likely the account has not had it's first sign-in yet." 
        New-Item -ItemType Directory -Path $chromeUserDataPath
    }
    return $chromeUserDataPath
}
function getChromeProfiles {
    param (
        [Parameter(Mandatory = $true)]
        [string]$userPath
    )
    
    $profiles = [ordered]@{}
    $profileFolders = Get-ChildItem -Path $userPath -Directory

    if ($null -eq $profileFolders) { 
        New-Item -ItemType Directory -Path "$userPath\Default" -Force
    }

    foreach ($profileFolder in $profileFolders) {
        $preferencesFile = Join-Path -Path $profileFolder.FullName -ChildPath "Preferences"
        if (Test-Path -Path $preferencesFile) {
            $preferencesContent = Get-Content -Path $preferencesFile -Raw | ConvertFrom-Json
            $profileName = $preferencesContent.account_info.email

            if ($null -eq $preferencesContent.account_info.email) {
                $profileName = $preferencesContent.account_info.account_id
            } 

            $folderName = Split-Path -Path $profileFolder.FullName -Leaf

            if ($null -eq $profileName) {
                $profiles["$folderName"] = $folderName
            } else {
                $profiles["$profileName"] = $folderName
            }
        }
    }

    return $profiles
}
function updateChromePreferences {
    param (
        [Parameter(Mandatory = $true)]
        [string]$profile
    )

    $preferencesFilePath = Join-Path -Path $profile -ChildPath "Preferences"
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
    }
}