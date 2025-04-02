# --- Configuration ---
$RestartIntervalDays = 7
$RestartTimeHour = 18 # 6 PM in 24-hour format
$RestartTimeMinute = 30
param(
    [string]$LogFilePath = $env:LOG_FILE_PATH -or "C:\Scripts\RestartLog.txt" # Default to environment variable or fallback
)
$NotificationTitle = "Automated Restart"
$NotificationBody = "This computer will restart in 60 seconds for performance improvements. Please save your work."
$ShutdownTimeoutSeconds = 60 # Time to wait for applications to close gracefully
$SleepDurationSeconds = 60   # Duration to pause before initiating restart (configurable)

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
    param(
        [Parameter(Mandatory=$true)]
        [int]$Timeout # in seconds
    )
    try {
        Write-Log -LogMessage "Attempting graceful shutdown with a timeout of $($Timeout) seconds."
        Stop-Computer -Force -Timeout $Timeout
        Write-Log -LogMessage "Restart command initiated."
    } catch {
        Write-Log -LogMessage "Error initiating restart: $($_.Exception.Message)"
        # Consider adding more specific error handling here if needed
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