function addInTechAdmin {
    try {
        $accountName = "InTechAdmin"
        $keyDownload = getDownload -url "https://drive.google.com/uc?export=download&id=1EGASU9cvnl5E055krXXcXUcgbr4ED4ry" -target "$env:SystemRoot\Temp\KEY.txt" -lineBefore
        $phraseDownload = getDownload -url "https://drive.google.com/uc?export=download&id=1jbppZfGusqAUM2aU7V4IeK0uHG2OYgoY" -target "$env:SystemRoot\Temp\PHRASE.txt" -lineBefore

        if ($keyDownload -eq $true -and $phraseDownload -eq $true) { 
            $password = Get-Content -Path "$env:SystemRoot\Temp\PHRASE.txt" | ConvertTo-SecureString -Key (Get-Content -Path "$env:SystemRoot\Temp\KEY.txt")

            writeText -type "plain" -text "Phrase converted." -lineBefore

            # Check if the InTechAdmin user already exists
            $account = Get-LocalUser -Name $accountName -ErrorAction SilentlyContinue

            if ($null -eq $account) {
                # Create the InTechAdmin user with specified password and attributes
                New-LocalUser -Name $accountName -Password $password -FullName "" -Description "InTech Administrator" -AccountNeverExpires -PasswordNeverExpires -ErrorAction stop | Out-Null
                writeText -type "notice" -text "Account created." -lineBefore
            } else {
                # Update the existing InTechAdmin user's password
                writeText -type "notice" -text "Account already exists." -lineBefore
                $account | Set-LocalUser -Password $password
                writeText -type "notice" -text "Password updated."
            }

            # Add the InTechAdmin user to the Administrators, Remote Desktop Users, and Users groups
            Add-LocalGroupMember -Group "Administrators" -Member $accountName -ErrorAction SilentlyContinue
            writeText -type "notice" -text "Account added to 'Administrators' group."
            Add-LocalGroupMember -Group "Remote Desktop Users" -Member $accountName -ErrorAction SilentlyContinue
            writeText -type "notice" -text "Account added to 'Remote Desktop Users' group."
            Add-LocalGroupMember -Group "Users" -Member $accountName -ErrorAction SilentlyContinue
            writeText -type "notice" -text "Account added to 'Users' group."

            # Remove the downloaded files for security reasons
            Remove-Item -Path "$env:SystemRoot\Temp\PHRASE.txt"
            Remove-Item -Path "$env:SystemRoot\Temp\KEY.txt"

            # Informational messages about deleting temporary files
            if (-not (Test-Path -Path "$env:SystemRoot\Temp\KEY.txt")) {
                writeText -type "plain" -text "Encryption key deleted." -lineBefore
            } else {
                writeText -type "plain" -text "Encryption key not deleted!" -lineBefore
            }
        
            if (-not (Test-Path -Path "$env:SystemRoot\Temp\PHRASE.txt")) {
                writeText -type "plain" -text "Encryption phrase deleted."
            } else {
                writeText -type "plain" -text "Encryption phrase not deleted!"
            }

            writeText -type "success" -text "InTech admin account created"
        }
    } catch {
        writeText -type "error" -text "addInTechAdmin-$($_.InvocationInfo.ScriptLineNumber) | $($_.Exception.Message)"
    }
}
