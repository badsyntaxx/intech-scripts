function schedule-reboot {
    # Create the action to restart the computer
    $action = New-ScheduledTaskAction -Execute "shutdown" -Argument "/r /t 0"

    # Calculate the next Wednesday at 10 PM
    $today = Get-Date
    $nextWednesday = $today.AddDays(3 - $today.DayOfWeek)
    $nextWednesday = $nextWednesday.AddHours(22)

    # Create the trigger for every Wednesday at 10 PM
    $trigger = New-ScheduledTaskTrigger -StartBoundary $nextWednesday -Repetition ('Weekly') -Enabled $true -TaskTriggerType 'Weekly'

    # Create the task principal (adjust as needed)
    $principal = New-ScheduledTaskPrincipal -LogonType Interactive

    # Register the task
    Register-ScheduledTask -TaskName "WeeklyReboot" -Action $action -Trigger $trigger -Principal $principal
}