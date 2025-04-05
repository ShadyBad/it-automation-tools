<#
Automates system restart checks and initiates a restart if the configured interval has been reached.

.DESCRIPTION
This script checks the last system restart time and compares it to a configurable interval (in days). 
If the interval has been exceeded, it notifies the user and initiates a system restart after a configurable delay. 
The script logs all actions and errors to a specified log file.

.PARAMETER LogFilePath
Specifies the path to the log file where script actions and errors will be recorded. 
Defaults to "C:\Scripts\RestartLog.txt". Can be overridden by the environment variable LOG_FILE_PATH.

.PARAMETER RestartIntervalDays
Specifies the number of days between restarts. Defaults to 7 days.

.PARAMETER RestartTimeHour
Specifies the hour of the day when the restart should occur. Defaults to 18 (6 PM).

.PARAMETER RestartTimeMinute
Specifies the minute of the hour when the restart should occur. Defaults to 00.

.PARAMETER NotificationTitle
Specifies the title of the notification displayed to the user before the restart. Defaults to "Automated Restart".

.PARAMETER NotificationBody
Specifies the body of the notification displayed to the user before the restart. 
Defaults to "This computer will restart in 60 seconds for performance improvements. Please save your work."

.PARAMETER ShutdownTimeoutSeconds
Specifies the timeout in seconds before the system restart is initiated. Defaults to 60 seconds.

.PARAMETER SleepDurationSeconds
Specifies the duration in seconds to wait after notifying the user before initiating the restart. Defaults to 60 seconds.

.FUNCTIONS
Write-Log
Logs messages to the specified log file. Creates the log directory if it does not exist.

Get-LastRestartTime
Retrieves the last system restart time using the Win32_OperatingSystem CIM class.

Should-Restart
Determines if a restart is needed based on the last restart time and the configured interval.

Show-Notification
Displays a notification to the user. Uses the BurntToast module if available, otherwise falls back to a message box.

Initiate-Restart
Initiates a system restart using the Restart-Computer cmdlet with the -Force parameter.

.NOTES
- Requires administrative privileges to execute.
- The BurntToast module is optional but recommended for better notification support.
- Ensure the log file path is accessible and writable by the script.

.EXAMPLE
.\windows_restart.ps1
Runs the script with default parameters, checking if a restart is needed and initiating it if the interval has been exceeded.

.EXAMPLE
.\windows_restart.ps1 -LogFilePath "D:\Logs\RestartLog.txt"
Runs the script with a custom log file path.

.EXAMPLE
$env:LOG_FILE_PATH = "D:\Logs\CustomLog.txt"
.\windows_restart.ps1
Overrides the default log file path using an environment variable.

#>
param(
    [string]$LogFilePath = "C:\Scripts\RestartLog.txt"
)
# Check if the environment variable exists and override if it does
if ($env:LOG_FILE_PATH) {
    $LogFilePath = $env:LOG_FILE_PATH
}

# --- Configuration ---
$RestartIntervalDays = 7
$RestartTimeHour = 18
$RestartTimeMinute = 00
$NotificationTitle = "Automated Restart"
$NotificationBody = "This computer will restart in 60 seconds for performance improvements. Please save your work."
$ShutdownTimeoutSeconds = 60
$SleepDurationSeconds = 60

# --- Functions ---

function Write-Log {
    param(
        [Parameter(Mandatory=$true)]
        [string]$LogMessage
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "$Timestamp - $LogMessage"
    $LogDirectory = Split-Path -Path $LogFilePath
    if (-not (Test-Path -Path $LogDirectory)) {
        try {
            New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
        } catch {
            Write-Warning "Could not create log directory: $($_.Exception.Message)"
        }
    }
    try {
        Add-Content -Path $LogFilePath -Value $LogEntry
    } catch {
        Write-Warning "Could not write to log file: $($_.Exception.Message)"
    }
}

function Get-LastRestartTime {
    try {
        $OperatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem
        if ($OperatingSystem) {
            return $OperatingSystem.LastBootUpTime
        } else {
            Write-Log -LogMessage "Error: Could not retrieve operating system information."
            return $null
        }
    } catch {
        Write-Log -LogMessage "Error retrieving last restart time: $($_.Exception.Message)"
        return $null
    }
}

function Should-Restart {
    param(
        [Parameter(Mandatory=$true)]
        [datetime]$LastRestartTime,
        [Parameter(Mandatory=$true)]
        [int]$IntervalDays
    )
    $TimeDifference = (Get-Date) - $LastRestartTime
    if ($TimeDifference.Days -ge $IntervalDays) {
        return $true
    } else {
        return $false
    }
}

function Show-Notification {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title,
        [Parameter(Mandatory=$true)]
        [string]$Body
    )
    try {
        if (-not (Get-Module -Name BurntToast -ListAvailable)) {
            Write-Log -LogMessage "BurntToast module not found. Please install it using 'Install-Module -Name BurntToast'."
            # Fallback to MessageBox if BurntToast is not available
            Add-Type -AssemblyName System.Windows.Forms | Out-Null
            [System.Windows.Forms.MessageBox]::Show($Body, $Title, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
            return
        }
        Import-Module BurntToast -ErrorAction Stop | Out-Null
        New-BurntToastNotification -Text $Title, $Body
    } catch {
        Write-Log -LogMessage "Error displaying notification: $($_.Exception.Message)"
        # Fallback to MessageBox if BurntToast fails
        try {
            Add-Type -AssemblyName System.Windows.Forms | Out-Null
            [System.Windows.Forms.MessageBox]::Show($Body, $Title, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
        } catch {
            Write-Log -LogMessage "Error displaying fallback notification."
        }
    }
}

function Initiate-Restart {
    # Keep the parameter block as is for now, though -Timeout isn't used by Restart-Computer the same way.
    param(
        [Parameter(Mandatory=$true)]
        [int]$Timeout # Parameter remains, but less relevant for Restart-Computer -Force
    )
    try {
        # Use Restart-Computer instead
        Write-Log -LogMessage "Attempting graceful restart with forced application close."
        Restart-Computer -Force
        # If the command succeeds, the script likely terminates here as the OS restarts.
        # This next log message might only appear if Restart-Computer fails immediately.
        Write-Log -LogMessage "Restart command initiated."
    } catch {
        Write-Log -LogMessage "Error initiating restart: $($_.Exception.Message)"
    }
}
# --- Main Script ---
Write-Log -LogMessage "Script started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'). Purpose: Automated system restart check."

$LastRestart = Get-LastRestartTime

if ($LastRestart) {
    if (Should-Restart -LastRestartTime $LastRestart -IntervalDays $RestartIntervalDays) {
        Write-Log -LogMessage "Restart interval of $($RestartIntervalDays) days reached. Last restart was $($LastRestart)."
        Show-Notification -Title $NotificationTitle -Body $NotificationBody

        Write-Log -LogMessage "Waiting $($SleepDurationSeconds) seconds before initiating restart."
        Start-Sleep -Seconds $SleepDurationSeconds # Give users a configurable time to save

        Initiate-Restart -Timeout $ShutdownTimeoutSeconds
    } else {
        $TimeDifference = (Get-Date) - $LastRestart
        Write-Log -LogMessage "Restart not needed. Last restart was $($LastRestart). Next check in $($RestartIntervalDays - $TimeDifference.Days) days."
    }
} else {
    Write-Log -LogMessage "Could not determine last restart time. Skipping restart check."
}

Write-Log -LogMessage "Script finished at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')."
