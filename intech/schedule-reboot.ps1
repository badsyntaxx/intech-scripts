function schedule-reboot {
    try {
        write-text "Creating the InTech weekly reboot task."
        $taskName = "InTech Weekly Reboot"

        # Check if the task already exists
        $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    
        if ($existingTask) {
            write-text -type 'success' -text "Task '$taskName' already exists. Skipping task creation."
        } else {
            # Define the action (reboot) and trigger (weekly on Wednesday at 10 PM)
            $action = New-ScheduledTaskAction -Execute 'shutdown' -Argument '/r /t 0'
            $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Wednesday -At 10:00PM
    
            # Create the task
            Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $taskName -User 'NT AUTHORITY\SYSTEM' -RunLevel Highest | Out-Null

            write-text -type "success" -text "Task '$taskName' created successfully."
            write-text "The system will now reboot every Wednesday at 10PM."
        }
    } catch {
        # Display error message and exit this script
        write-text -type "error" -text "schedule-reboot-$($_.InvocationInfo.ScriptLineNumber) | $($_.Exception.Message)" -lineAfter
    } 
}