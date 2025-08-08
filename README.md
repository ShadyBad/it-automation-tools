# IT Automation Tools

![Python](https://img.shields.io/badge/python-3.x-blue.svg)
![PowerShell](https://img.shields.io/badge/powershell-5.1%2B-blue.svg)
![Bash](https://img.shields.io/badge/bash-5.0%2B-green.svg)
![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS-lightgrey.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

A comprehensive collection of enterprise-grade IT automation tools designed to streamline common administrative tasks, enhance security compliance, and improve operational efficiency across Windows and macOS environments.

## 🚀 Overview

This repository provides a suite of production-ready automation tools that address common IT administration challenges in enterprise environments. Each tool is designed with security, reliability, and ease of deployment in mind, supporting both manual execution and integration with enterprise management platforms like Microsoft Intune, SCCM, and Kandji.

## ✨ Features

### Core Capabilities
- **Cross-Platform Support**: Tools for both Windows and macOS environments
- **Enterprise-Ready**: Designed for deployment via MDM/MAM solutions
- **Comprehensive Logging**: Detailed logging for audit and troubleshooting
- **Error Handling**: Robust error handling with graceful failure modes
- **Security-First**: Built with enterprise security requirements in mind
- **Minimal Dependencies**: Leverages native OS capabilities where possible

### Key Benefits
- Reduces manual intervention for routine tasks
- Ensures consistent configuration across enterprise endpoints
- Improves security compliance (SSL/TLS certificate management)
- Enhances system stability through automated maintenance
- Streamlines data processing workflows

## 🛠️ Tools Included

### JSON to CSV Converter

**File**: `json_to_csv.py`  
**Platform**: Cross-platform (Windows/macOS/Linux)  
**Language**: Python 3.x

A high-performance data transformation utility that merges multiple JSON files into a single CSV file using the Polars library for optimal memory efficiency.

#### Features
- Processes multiple JSON files in a single operation
- Memory-efficient processing using Polars DataFrame
- Automatic data type optimization (shrink_dtype)
- Input validation and comprehensive error handling
- Interactive filename specification
- Configurable output directory

#### Use Cases
- Consolidating API responses
- Merging log files for analysis
- Data migration and ETL processes
- Report generation from multiple data sources

### Windows Auto-Restart Manager

**File**: `windows_restart.ps1`  
**Platform**: Windows 10/11, Windows Server 2016+  
**Language**: PowerShell 5.1+

An intelligent system restart automation tool that ensures Windows systems are regularly restarted for optimal performance and security update application.

#### Features
- **Configurable Restart Schedule**: Default 7-day interval at 6 PM
- **User Notification System**: 
  - BurntToast notifications (if available)
  - Fallback to Windows Forms MessageBox
- **Grace Period**: 60-second warning before restart
- **Comprehensive Logging**: Detailed activity logs for compliance
- **Environment Variable Support**: Override configuration via environment variables
- **Last Boot Time Detection**: Uses WMI for accurate uptime calculation
- **Administrative Privilege Handling**: Proper elevation and error handling

#### Configuration Parameters
- `RestartIntervalDays`: Days between restarts (default: 7)
- `RestartTimeHour`: Hour of day for restart (default: 18/6 PM)
- `NotificationTitle`: Customizable notification title
- `ShutdownTimeoutSeconds`: Grace period before restart (default: 60)
- `LogFilePath`: Configurable log location

#### Use Cases
- Scheduled maintenance windows
- Memory leak mitigation
- Windows Update completion
- Performance optimization
- Compliance with IT policies

### Microsoft Edge Framework Threat Remediation

**File**: `edge_framework_remediation.sh`  
**Platform**: macOS 10.15+ (Catalina and later)  
**Language**: Bash

Enterprise-grade security remediation tool for removing outdated Microsoft Edge Framework versions that pose security threats.

#### Features
- Targets specific vulnerable framework version (138.0.3351.83)
- Force-quits Microsoft Edge and Teams for safe removal
- Clears Microsoft AutoUpdate cache
- Comprehensive logging for compliance auditing
- Verification of successful threat removal
- System information logging for forensics

#### Use Cases
- Security incident response
- Vulnerability remediation
- Compliance enforcement
- Automated threat removal via MDM

### Zscaler Certificate Trust Configuration

#### Windows Version

**File**: `zscaler_cert_trust_add.ps1`  
**Platform**: Windows 10/11, Windows Server 2016+  
**Language**: PowerShell 5.1+

Comprehensive SSL/TLS certificate trust configuration for Zscaler proxy environments on Windows systems.

##### Supported Applications
- **Java**: Imports into JVM keystore
- **Ruby**: Sets SSL_CERT_FILE environment variable
- **PowerShell**: Configures SSL trust for cmdlets
- **AWS CLI**: Sets AWS_CA_BUNDLE
- **Boto (Python SDK)**: Sets BOTO_CA_BUNDLE
- **Azure CLI**: Sets AZURE_CA_BUNDLE

##### Features
- Automatic certificate extraction from Windows Certificate Store
- Internet connectivity verification
- Application detection and conditional configuration
- Temporary file cleanup
- Execution timing and performance metrics
- Detailed transaction logging

#### macOS Version

**File**: `zscaler_cert_trust_store_add.sh`  
**Platform**: macOS 10.15+ (Catalina and later)  
**Language**: Bash

Enterprise-grade SSL/TLS certificate trust configuration for Zscaler proxy environments on macOS systems.

##### Supported Applications
- **Google Cloud SDK**: Custom CA certificate configuration
- **Rust/Cargo**: HTTP cainfo configuration
- **Salesforce CLI**: NODE_EXTRA_CA_CERTS
- **Composer (PHP)**: COMPOSER_CAFILE
- **Ruby**: SSL_CERT_FILE
- **Docker**: Certificate installation in system store
- **npm/Node.js**: Certificate bundle configuration

##### Features
- Automatic privilege escalation (sudo)
- Keychain certificate extraction
- Configuration file backup before modification
- Duplicate entry prevention
- Shell profile integration (.zshrc)
- Comprehensive error handling
- MDM/Kandji integration support

## 💻 System Requirements

### General Requirements
- Administrative/root privileges for system-level configurations
- Internet connectivity for certificate validation tools

### Python Tools
- Python 3.7 or later
- pip package manager
- Polars library (for json_to_csv.py)

### Windows PowerShell Tools
- Windows 10 version 1709 or later / Windows Server 2016 or later
- PowerShell 5.1 or PowerShell Core 7.x
- .NET Framework 4.5 or later
- Windows Management Instrumentation (WMI) enabled

### macOS Bash Tools
- macOS 10.15 (Catalina) or later
- Bash 5.0 or later
- Security command-line tool (included with macOS)
- Valid Keychain access

## 📦 Installation

### Clone the Repository
```bash
git clone https://github.com/yourusername/it-automation-tools.git
cd it-automation-tools
```

### Python Dependencies
```bash
# Install Polars for json_to_csv.py
pip install polars

# Or use requirements file if provided
pip install -r requirements.txt
```

### PowerShell Module Dependencies (Optional)
```powershell
# For enhanced notifications in windows_restart.ps1
Install-Module -Name BurntToast -Force -AllowClobber
```

### Setting Execution Policy (Windows)
```powershell
# Allow script execution (Administrator required)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
```

### Making Scripts Executable (macOS/Linux)
```bash
chmod +x zscaler_cert_trust_store_add.sh
chmod +x edge_framework_remediation.sh
```

## 📖 Usage Examples

### JSON to CSV Converter

#### Basic Usage
```bash
# Convert single JSON file
python json_to_csv.py data.json

# Merge multiple JSON files
python json_to_csv.py api_response1.json api_response2.json api_response3.json

# When prompted, enter output filename
Enter the filename (e.g. 'data.csv'): merged_data.csv
```

#### Sample JSON Input Format
```json
[
  {"id": 1, "name": "John Doe", "department": "IT"},
  {"id": 2, "name": "Jane Smith", "department": "HR"}
]
```

### Windows Auto-Restart Manager

#### Manual Execution
```powershell
# Run with default settings (7 days, 6 PM)
.\windows_restart.ps1

# Custom log file location
.\windows_restart.ps1 -LogFilePath "D:\Logs\RestartLog.txt"

# Using environment variable for log path
$env:LOG_FILE_PATH = "D:\CustomLogs\restart.log"
.\windows_restart.ps1
```

#### Task Scheduler Integration
```powershell
# Create scheduled task to run daily at 6 PM
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File C:\Scripts\windows_restart.ps1"
$trigger = New-ScheduledTaskTrigger -Daily -At "18:00"
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest
Register-ScheduledTask -TaskName "AutoRestartCheck" `
    -Action $action -Trigger $trigger -Principal $principal
```

#### Intune Deployment
1. Upload script to Intune
2. Configure as PowerShell script
3. Set to run in system context
4. Assign to device groups

### Microsoft Edge Framework Remediation

#### Standard Execution
```bash
# Run with sudo (required for system modifications)
sudo ./edge_framework_remediation.sh

# The script will automatically:
# 1. Force-quit Microsoft Edge and Teams
# 2. Remove vulnerable framework versions
# 3. Clear AutoUpdate cache
# 4. Verify successful removal
# 5. Generate compliance log at /var/tmp/kandji_edge_remediation.log
```

#### Kandji/MDM Deployment
```bash
# Deploy via Kandji Custom Script
# Set to run as root
# Configure as remediation script for threat detection
# Log output will be at /var/tmp/kandji_edge_remediation.log
```

#### Verification
```bash
# Check log file for results
cat /var/tmp/kandji_edge_remediation.log

# Verify framework removal
ls -la "/Applications/Microsoft Edge.app/Contents/Frameworks/Microsoft Edge Framework.framework/Versions/"
ls -la "/Applications/Microsoft Teams.app/Contents/Helpers/Microsoft Teams WebView.app/Contents/Frameworks/"
```

### Zscaler Certificate Trust - Windows

#### Standard Execution
```powershell
# Run with administrative privileges
.\zscaler_cert_trust_add.ps1

# The script will automatically:
# 1. Export Zscaler cert from Windows store
# 2. Configure all detected applications
# 3. Clean up temporary files
# 4. Generate execution report
```

#### Silent Execution for Deployment
```powershell
# For SCCM/Intune deployment
PowerShell.exe -ExecutionPolicy Bypass -File .\zscaler_cert_trust_add.ps1 -WindowStyle Hidden
```

### Zscaler Certificate Trust - macOS

#### Standard Execution
```bash
# Run with sudo (will auto-escalate if needed)
sudo ./zscaler_cert_trust_store_add.sh

# Or let the script handle elevation
./zscaler_cert_trust_store_add.sh
```

#### MDM/Kandji Deployment
```bash
# Deploy via Kandji Custom Script
# Set to run as root
# Include in baseline or remediation policy
```

#### Verification
```bash
# Verify certificate extraction
security find-certificate -c "Zscaler Root CA" -p

# Check environment variables
env | grep -E "(SSL_CERT|CA_BUNDLE|CAFILE)"

# Test SSL connections
curl https://www.google.com -v
```

## 🔒 Security Considerations

### Certificate Management
- **Validation**: Always verify certificate authenticity before trusting
- **Scope**: Certificate trust is configured system-wide
- **Rotation**: Implement certificate rotation procedures
- **Monitoring**: Monitor certificate expiration dates
- **Backup**: Maintain backups of original trust stores

### Script Execution
- **Privileges**: Scripts require administrative/root access
- **Validation**: Verify script integrity before execution
- **Logging**: Review logs regularly for anomalies
- **Testing**: Test in non-production environments first
- **Rollback**: Maintain rollback procedures

### Data Handling
- **Sensitive Data**: Avoid processing sensitive data without encryption
- **File Permissions**: Ensure appropriate file permissions on outputs
- **Temporary Files**: Scripts clean up temporary files automatically
- **Log Sanitization**: Logs do not contain sensitive information

### Network Security
- **Proxy Awareness**: Scripts are proxy-aware where applicable
- **TLS Validation**: Maintains TLS validation except for trusted proxies
- **Connectivity Checks**: Scripts verify connectivity before operations

## 🤝 Contributing

We welcome contributions from the community! Please follow these guidelines:

### Getting Started
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Contribution Guidelines
- **Code Style**: Follow existing code style and conventions
- **Documentation**: Update README and inline documentation
- **Testing**: Include test cases for new functionality
- **Commits**: Use clear, descriptive commit messages
- **Issues**: Open an issue for major changes before starting work

### Code Review Process
1. All submissions require review before merging
2. Continuous integration checks must pass
3. Documentation must be updated
4. Security implications must be considered

## 📞 Support

### Documentation
- Review this README thoroughly
- Check inline script documentation
- Review script parameters and examples

### Issue Reporting
When reporting issues, please include:
- Script name and version
- Operating system and version
- Full error messages
- Steps to reproduce
- Expected vs. actual behavior

### Getting Help
- **Issues**: Open an issue on GitHub
- **Discussions**: Use GitHub Discussions for questions
- **Security**: Report security issues privately

## 📄 License

This project is licensed under the MIT License - see below for details:

```
MIT License

Copyright (c) 2025 Brandon Shay

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

<div align="center">
Made for the IT Community
</div>