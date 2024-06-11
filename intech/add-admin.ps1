function add-admin {
    try {
        $accountName = "InTechAdmin"
        $downloads = [ordered]@{
            "$env:TEMP\KEY.txt"    = "https://drive.google.com/uc?export=download&id=1EGASU9cvnl5E055krXXcXUcgbr4ED4ry"
            "$env:TEMP\PHRASE.txt" = "https://drive.google.com/uc?export=download&id=1jbppZfGusqAUM2aU7V4IeK0uHG2OYgoY"
        }

        foreach ($d in $downloads.Keys) { $download = get-download -Url $downloads[$d] -Target $d } 
        if (!$download) { throw "Unable to acquire credentials." }

        Write-Host
        if (Test-Path -Path "$env:TEMP\KEY.txt") {
            write-text -type "success" -text "The key was acquired"
        }

        if (Test-Path -Path "$env:TEMP\PHRASE.txt") {
            write-text -type "success" -text "The phrase was acquired"
        } 

        $password = Get-Content -Path "$env:TEMP\PHRASE.txt" | ConvertTo-SecureString -Key (Get-Content -Path "$env:TEMP\KEY.txt")

        write-text -type "done" -text "Phrase converted."

        $account = Get-LocalUser -Name $accountName -ErrorAction SilentlyContinue

        if ($null -eq $account) {
            New-LocalUser -Name $accountName -Password $password -FullName "" -Description "InTech Administrator" -AccountNeverExpires -PasswordNeverExpires -ErrorAction stop | Out-Null
            write-text -type "success" -text "The InTechAdmin account has been created"
        } else {
            write-text -type "notice" -text "InTechAdmin account already exists"
            $account | Set-LocalUser -Password $password
            write-text -type "success" -text "The InTechAdmin account password was updated"
        }

        Add-LocalGroupMember -Group "Administrators" -Member $accountName -ErrorAction SilentlyContinue
        write-text -type "success" -text "The InTechAdmin account has been added to the 'Administrators' group"
        Add-LocalGroupMember -Group "Remote Desktop Users" -Member $accountName -ErrorAction SilentlyContinue
        write-text -type "success" -text "The InTechAdmin account has been added to the 'Remote Desktop Users' group"
        Add-LocalGroupMember -Group "Users" -Member $accountName -ErrorAction SilentlyContinue
        write-text -type "success" -text "The InTechAdmin account has been added to the 'Users' group"

        Remove-Item -Path "$env:TEMP\PHRASE.txt"
        Remove-Item -Path "$env:TEMP\KEY.txt"

        if (-not (Test-Path -Path "$env:TEMP\KEY.txt")) {
            write-text -text "Encryption key wiped clean." -lineAfter
        }
        
        if (-not (Test-Path -Path "$env:TEMP\PHRASE.txt")) {
            write-text -text "Encryption phrase wiped clean." -lineAfter
        }

        read-command
    } catch {
        # Display error message and end the script
        exit-script -type "error" -text "add-intechadmin-$($_.InvocationInfo.ScriptLineNumber) | $($_.Exception.Message)" -LineAfter
    }
}
