function edit-hostname {
    try {
        write-welcome -Title "Edit Hostname" -Description "Edit the hostname and description of this computer." -Command "edit hostname"

        # Get the current hostname and description
        $currentHostname = $env:COMPUTERNAME
        $currentDescription = (Get-WmiObject -Class Win32_OperatingSystem).Description

        # Prompt user to enter a new hostname with validation
        write-text -Type "header" -Text "Enter hostname" -LineBefore -LineAfter
        $hostname = get-input -Validate "^(\s*|[a-zA-Z0-9 _\-]{1,15})$" -Value $currentHostname

        # Prompt user to enter a new description with validation
        write-text -Type "header" -Text "Enter description" -LineBefore -LineAfter
        $description = get-input -Validate "^(\s*|[a-zA-Z0-9 |_\-]{1,64})$" -Value $currentDescription

        # If user leaves hostname blank, keep the current one
        if ($hostname -eq "") { $hostname = $currentHostname } 

        # If user leaves description blank, keep the current one
        if ($description -eq "") { $description = $currentDescription } 

        # Warn user about changing hostname and description
        write-text -Type "header" -Text "YOU'RE ABOUT TO CHANGE THE COMPUTER NAME AND DESCRIPTION" -LineBefore -LineAfter
        
        # Confirm the changes with the user
        get-closing -Script "edit-hostname"

        # If hostname changed, update registry keys
        if ($hostname -ne $currentHostname) {
            Remove-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -name "Hostname" 
            Remove-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -name "NV Hostname" 
            Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Control\Computername\Computername" -name "Computername" -value $hostname
            Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Control\Computername\ActiveComputername" -name "Computername" -value $hostname
            Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -name "Hostname" -value $hostname
            Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -name "NV Hostname" -value  $hostname
            Set-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -name "AltDefaultDomainName" -value $hostname
            Set-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -name "DefaultDomainName" -value $hostname
            $env:COMPUTERNAME = $hostname
        } 

        # If description changed, update WMI object
        if ($description -ne $currentDescription) {
            Set-CimInstance -Query 'Select * From Win32_OperatingSystem' -Property @{Description = $description }
        } 

        # Success message after changes applied
        exit-script -Type "success" -Text "The PC name changes have been applied. No restart required!" -LineAfter
    } catch {
        # Display error message and end the script
        exit-script -Type "error" -Text "edit-hostname-$($_.InvocationInfo.ScriptLineNumber) | $($_.Exception.Message)" -LineAfter
    }
}

