function edit-user-password {
    try {
        write-welcome -Title "Edit User Password" -Description "Edit an existing users Password." -Command "edit user password"

        # Prompt user to select a user
        $user = select-user

        # Check if user is local or domain-based
        if ($user["Source"] -eq "Local") { Edit-LocalUserPassword -Username $user["Name"] } else { Edit-ADUserPassword }
    } catch {
        # Display error message and end the script
        exit-script -Type "error" -Text "edit-user-password-$($_.InvocationInfo.ScriptLineNumber) | $($_.Exception.Message)" -LineAfter
    }
}

function Edit-LocalUserPassword {
    param (
        [Parameter(Mandatory)]
        [string]$Username
    )

    try {
        # Prompt user to enter a new password securely (blank removes password)
        write-text -Type "header" -Text "Enter password or leave blank" -LineAfter
        $password = get-input -Prompt "" -IsSecure $true

        # Craft warning message based on user input
        if ($password.Length -eq 0) { $alert = "YOU'RE ABOUT TO REMOVE THIS USERS PASSWORD!" } 
        else { $alert = "YOU'RE ABOUT TO CHANGE THIS USERS PASSWORD" }

        # Confirm the change
        write-text -Type "header" -Text $alert -LineBefore -LineAfter
        get-closing -Script "edit-user-password"

        # Apply the change
        Get-LocalUser -Name $Username | Set-LocalUser -Password $password

        # Display success and exit script
        exit-script -Type "success" -Text "The password for this account has been changed." -LineAfter
    } catch {
        # Display error message and end the script
        exit-script -Type "error" -Text "Edit-LocalUserPassword-$($_.InvocationInfo.ScriptLineNumber) | $($_.Exception.Message)" -LineAfter
    }
}

function Edit-ADUserPassword {
    exit-script -Type "fail" -Text "Editing domain users doesn't work yet."
}

