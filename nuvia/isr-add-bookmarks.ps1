function isr-add-bookmarks {
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

        $choice = read-option -options $profiles -prompt "Select a Chrome profile:" -ReturnKey 
        $account = $profiles["$choice"]
        $boomarksUrl = "https://drive.google.com/uc?export=download&id=1WmvSnxtDSLOt0rgys947sOWW-v9rzj9U"

        $download = get-download -Url $boomarksUrl -Target "$env:SystemRoot\Temp\Bookmarks"
        if (!$download) { 
            throw "Unable to acquire bookmarks." 
        }

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
            write-text -type "success" -text "The bookmarks have been added."
        }
    } catch {
        # Display error message and end the script
        write-text -type "error" -text "isr-add-bookmarks-$($_.InvocationInfo.ScriptLineNumber) | $($_.Exception.Message)"
    }
}