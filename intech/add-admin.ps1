function add-admin {
    try {
        # Define the account name for the admin user
        $accountName = "InTechAdmin"

        # Define a hashtable to store download URLs and their target paths for the encrypted password
        $downloads = [ordered]@{
            "$env:SystemRoot\Temp\KEY.txt"    = "https://drive.google.com/uc?export=download&id=1EGASU9cvnl5E055krXXcXUcgbr4ED4ry"
            "$env:SystemRoot\Temp\PHRASE.txt" = "https://drive.google.com/uc?export=download&id=1jbppZfGusqAUM2aU7V4IeK0uHG2OYgoY"
        }

        # Loop through each download in the hashtable
        foreach ($d in $downloads.Keys) { $download = get-download -Url $downloads[$d] -Target $d -visible } 
        if (!$download) { throw "Unable to acquire credentials." }

        # Check if the KEY.txt file exists (indicating successful download)
        if (Test-Path -Path "$env:SystemRoot\Temp\KEY.txt") {
            write-text -type "success" -text "The key was acquired." -lineBefore
        }

        # Check if the PHRASE.txt file exists (indicating successful download)
        if (Test-Path -Path "$env:SystemRoot\Temp\PHRASE.txt") {
            write-text -type "success" -text "The phrase was acquired."
        } 

        # Read the password phrase from PHRASE.txt and convert it to a secure string
        # using the key from KEY.txt
        $password = Get-Content -Path "$env:SystemRoot\Temp\PHRASE.txt" | ConvertTo-SecureString -Key (Get-Content -Path "$env:SystemRoot\Temp\KEY.txt")

        write-text -type "done" -text "Phrase converted."

        # Check if the InTechAdmin user already exists
        $account = Get-LocalUser -Name $accountName -ErrorAction SilentlyContinue

        if ($null -eq $account) {
            # Create the InTechAdmin user with specified password and attributes
            New-LocalUser -Name $accountName -Password $password -FullName "" -Description "InTech Administrator" -AccountNeverExpires -PasswordNeverExpires -ErrorAction stop | Out-Null
            write-text -type "success" -text "The InTechAdmin account has been created."
        } else {
            # Update the existing InTechAdmin user's password
            write-text -type "notice" -text "InTechAdmin account already exists."
            $account | Set-LocalUser -Password $password
            write-text -type "success" -text "The InTechAdmin account password was updated."
        }

        # Add the InTechAdmin user to the Administrators, Remote Desktop Users, and Users groups
        Add-LocalGroupMember -Group "Administrators" -Member $accountName -ErrorAction SilentlyContinue
        write-text -type "success" -text "The InTechAdmin account has been added to the 'Administrators' group."
        Add-LocalGroupMember -Group "Remote Desktop Users" -Member $accountName -ErrorAction SilentlyContinue
        write-text -type "success" -text "The InTechAdmin account has been added to the 'Remote Desktop Users' group."
        Add-LocalGroupMember -Group "Users" -Member $accountName -ErrorAction SilentlyContinue
        write-text -type "success" -text "The InTechAdmin account has been added to the 'Users' group."

        # Remove the downloaded files for security reasons
        Remove-Item -Path "$env:SystemRoot\Temp\PHRASE.txt"
        Remove-Item -Path "$env:SystemRoot\Temp\KEY.txt"

        # Informational messages about deleting temporary files
        if (-not (Test-Path -Path "$env:SystemRoot\Temp\KEY.txt")) {
            write-text -text "Encryption key deleted."
        } else {
            write-text -text "Encryption key not deleted!"
        }
        
        if (-not (Test-Path -Path "$env:SystemRoot\Temp\PHRASE.txt")) {
            write-text -text "Encryption phrase deleted." -lineAfter
        } else {
            write-text -text "Encryption phrase not deleted!" -lineAfter
        }

        # Function successful wait for new commands
        read-command
    } catch {
        # Display error message and end the script
        exit-script -type "error" -text "add-intechadmin-$($_.InvocationInfo.ScriptLineNumber) | $($_.Exception.Message)" -lineAfter
    }
}
