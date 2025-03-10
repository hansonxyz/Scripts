# Script: Idle HTTP Request Monitor
# Description:
#   This PowerShell script monitors the computer's idle state using the Windows API.
#   It executes an HTTP request every 30 seconds when the computer is active.
#   If the system is idle (no user input for 60 seconds), the script enters a faster-checking mode,
#   polling every 2 seconds until activity resumes.
#   State changes (active <-> idle) are logged with a timestamp.
#
# Implementation Details:
#   - A .NET type is defined to wrap the GetLastInputInfo API call, which retrieves the idle time.
#   - The script maintains a 'state' variable ("active" or "idle") to control behavior.
#   - In active state: Executes an HTTP request and checks every 30 seconds.
#   - In idle state: Only checks for activity every 2 seconds, without executing the HTTP request.
#
# Usage:
#   - Update the URI in Invoke-WebRequest with the desired endpoint.
#   - Run the script in a PowerShell session on a Windows computer.

Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class idle_time {
    [DllImport("user32.dll")]
    public static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);
    public static uint GetIdleTime() {
        LASTINPUTINFO lii = new LASTINPUTINFO();
        lii.cbSize = (uint)System.Runtime.InteropServices.Marshal.SizeOf(typeof(LASTINPUTINFO));
        GetLastInputInfo(ref lii);
        return ((uint)Environment.TickCount - lii.dwTime);
    }
}
public struct LASTINPUTINFO {
    public uint cbSize;
    public uint dwTime;
}
"@

# Initialize the state and polling interval.
$state = "active"
$interval = 30  # in seconds for active state

# Infinite monitoring loop.
while ($true) {
    # Retrieve the current idle time in milliseconds.
    $idle_ms = [idle_time]::GetIdleTime()
    
    if ($state -eq "active") {
        # If idle time exceeds or equals 60 seconds, switch to idle state.
        if ($idle_ms -ge 60000) {
            Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Idle state detected."
            $state = "idle"
            $interval = 2  # Faster polling when idle
        }
        else {
            # When active, execute the HTTP request.
            Invoke-WebRequest -Uri "http://your-endpoint.com" | Out-Null
        }
    }
    elseif ($state -eq "idle") {
        # If user activity resumes (idle time less than 60 seconds), switch to active state.
        if ($idle_ms -lt 60000) {
            Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Non-idle state detected."
            $state = "active"
            $interval = 30  # Return to slower polling
            # Execute an HTTP request upon detecting activity.
            Invoke-WebRequest -Uri "http://your-endpoint.com" | Out-Null
        }
    }
    # Wait for the specified interval before the next check.
    Start-Sleep -Seconds $interval
}
