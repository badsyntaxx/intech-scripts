function edit-user-name {
    try {
        write-welcome -Title "Edit User Name" -Description "Edit an existing users name." -Command "edit user name"

        # Prompt user to select a user
        $user = select-user

        # Check if user is local or domain-based
        if ($user["Source"] -eq "Local") { Edit-LocalUserName -User $user } else { Edit-ADUserName }
    } catch {
        # Display error message and end the script
        exit-script -Type "error" -Text "edit-user-name-$($_.InvocationInfo.ScriptLineNumber) | $($_.Exception.Message)" -LineAfter
    }
}

function Edit-LocalUserName {
    param (
        [Parameter(Mandatory)]
        [System.Collections.Specialized.OrderedDictionary]$User # OrderedDic = Associative array of user information.
    )

    try {
        # Prompt user to enter a new username with validation
        write-text -Type "header" -Text "Enter username" -LineAfter
        $newName = get-input -Validate "^(\s*|[a-zA-Z0-9 _\-]{1,64})$" -CheckExistingUser

        # Warning message before renaming
        write-text -Type "header" -Text "YOU'RE ABOUT TO CHANGE THIS USERS NAME." -LineBefore -LineAfter
        get-closing -Script "edit-user-name"
    
        # Rename the local user
        Rename-LocalUser -Name $User["Name"] -NewName $newName

        # Get the newly renamed user object
        $newUser = Get-LocalUser -Name $newName

        # Check if rename was successful
        if ($null -ne $newUser) { 
            # Get user data before and after rename for comparison
            $newData = get-userdata -Username $newUser
            write-text -Type "compare" -OldData $User -NewData $newData -LineAfter

            # Success message with details
            exit-script -Type "success" -Text "The name for this account has been changed." -LineAfter
        } else {
            # Error message if rename failed
            exit-script -Type "error" -Text "There was an unknown error when trying to rename this user." -LineAfter
        }
    } catch {
        # Display error message and end the script
        exit-script -Type "error" -Text "Edit-LocalUserName-$($_.InvocationInfo.ScriptLineNumber) | $($_.Exception.Message)" -LineAfter -LineAfter
    }
}

function Edit-ADUserName {
    write-text -Type "fail" -Text "Editing domain users doesn't work yet."
    write-text
}