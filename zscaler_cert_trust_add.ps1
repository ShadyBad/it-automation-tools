# Set Execution Policy to Allow Script Execution
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# Start Execution Timer
$startTime = Get-Date

# Configuration
$certName = "Zscaler Root CA"
$certExportPath = "$env:TEMP\zscaler-cert.cer"
$logFile = "$env:TEMP\zscaler_ssl_log.txt"

# Certificate Trust Locations
$javaKeyStore = "$env:JAVA_HOME\lib\security\cacerts"
$rubyCertFile = "$env:SSL_CERT_FILE"
$awsCertFile = "$env:AWS_CA_BUNDLE"
$botoCertFile = "$env:BOTO_CA_BUNDLE"
$azureCertFile = "$env:AZURE_CA_BUNDLE"

# Redirect Logs
Start-Transcript -Path $logFile -Append

Write-Host "Starting Intune Zscaler SSL configuration..."

# Check for Internet Connectivity
$internetCheck = Test-NetConnection -ComputerName "google.com" -InformationLevel Quiet
if (-not $internetCheck) {
    Write-Host "ERROR: No internet connection detected. Exiting..."
    Stop-Transcript
    exit 1
}

# Extract Zscaler Certificate from Windows Certificate Store
Write-Host "Extracting Zscaler certificate from Windows Certificate Store..."
try {
    $cert = Get-ChildItem -Path Cert:\LocalMachine\Root | Where-Object { $_.Subject -match $certName }
    if ($cert) {
        Export-Certificate -Cert $cert -FilePath $certExportPath -Force
        Write-Host "Zscaler certificate exported to $certExportPath."
    } else {
        Write-Host "ERROR: Zscaler certificate not found in Windows Certificate Store."
        Stop-Transcript
        exit 1
    }
} catch {
    Write-Host "ERROR: $($_.Exception.Message)"
    Stop-Transcript
    exit 1
}

# Install Certificate into Windows Trusted Root Store (if not already present)
if (-not (Get-ChildItem -Path Cert:\LocalMachine\Root | Where-Object { $_.Subject -match $certName })) {
    Write-Host "Installing Zscaler certificate into the Windows Trusted Root Store..."
    try {
        Import-Certificate -FilePath $certExportPath -CertStoreLocation Cert:\LocalMachine\Root
        Write-Host "Certificate successfully installed."
    } catch {
        Write-Host "ERROR: $($_.Exception.Message)"
        Stop-Transcript
        exit 1
    }
} else {
    Write-Host "Certificate already exists in the Trusted Root Store."
}

# Configure Java (if installed)
if (Test-Path $javaKeyStore) {
    Write-Host "Configuring Java SSL trust..."
    try {
        & "$env:JAVA_HOME\bin\keytool.exe" -importcert -trustcacerts -keystore $javaKeyStore -file $certExportPath -storepass changeit -noprompt
        Write-Host "Java now trusts the Zscaler certificate."
    } catch {
        Write-Host "ERROR: $($_.Exception.Message)"
    }
} else {
    Write-Host "Java is not installed. Skipping configuration."
}

# Configure Ruby (if installed)
if (Get-Command ruby -ErrorAction SilentlyContinue) {
    Write-Host "Configuring Ruby SSL trust..."
    try {
        [System.Environment]::SetEnvironmentVariable("SSL_CERT_FILE", $certExportPath, "Machine")
        Write-Host "Ruby now trusts the Zscaler certificate."
    } catch {
        Write-Host "ERROR: $($_.Exception.Message)"
    }
} else {
    Write-Host "Ruby is not installed. Skipping configuration."
}

# Configure Microsoft PowerShell
Write-Host "Configuring PowerShell SSL trust..."
try {
    Set-Item Env:\SSL_CERT_FILE $certExportPath
    Write-Host "PowerShell now trusts the Zscaler certificate."
} catch {
    Write-Host "ERROR: $($_.Exception.Message)"
}

# Configure AWS CLI (if installed)
if (Get-Command aws -ErrorAction SilentlyContinue) {
    Write-Host "Configuring AWS CLI SSL trust..."
    try {
        [System.Environment]::SetEnvironmentVariable("AWS_CA_BUNDLE", $certExportPath, "Machine")
        Write-Host "AWS CLI now trusts the Zscaler certificate."
    } catch {
        Write-Host "ERROR: $($_.Exception.Message)"
    }
} else {
    Write-Host "AWS CLI is not installed. Skipping configuration."
}

# Configure Boto (Python SDK) (if installed)
if (Get-Command python -ErrorAction SilentlyContinue) {
    Write-Host "Configuring Boto SSL trust..."
    try {
        [System.Environment]::SetEnvironmentVariable("BOTO_CA_BUNDLE", $certExportPath, "Machine")
        Write-Host "Boto now trusts the Zscaler certificate."
    } catch {
        Write-Host "ERROR: $($_.Exception.Message)"
    }
} else {
    Write-Host "Python is not installed. Skipping configuration."
}

# Configure Microsoft Azure CLI (if installed)
if (Get-Command az -ErrorAction SilentlyContinue) {
    Write-Host "Configuring Azure CLI SSL trust..."
    try {
        [System.Environment]::SetEnvironmentVariable("AZURE_CA_BUNDLE", $certExportPath, "Machine")
        Write-Host "Azure CLI now trusts the Zscaler certificate."
    } catch {
        Write-Host "ERROR: $($_.Exception.Message)"
    }
} else {
    Write-Host "Azure CLI is not installed. Skipping configuration."
}

# Cleanup Temporary Certificate File
if (Test-Path $certExportPath) {
    Write-Host "Cleaning up temporary certificate file..."
    try {
        Remove-Item -Path $certExportPath -Force
    } catch {
        Write-Host "ERROR: $($_.Exception.Message)"
    }
}

# End Execution Timer
$endTime = Get-Date
$elapsedTime = ($endTime - $startTime).TotalSeconds
Write-Host "Script completed in $elapsedTime seconds."

Write-Host "SSL Inspection configuration complete."
Stop-Transcript