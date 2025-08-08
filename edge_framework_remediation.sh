#!/bin/bash
#
# Microsoft Edge Framework Threat Remediation Script
# For Kandji deployment to remediate outdated Microsoft Edge Framework threats
# Version: 1.0
# Date: 2025-01-08
#
# This script removes outdated Microsoft Edge Framework version 138.0.3351.83
# from Microsoft Teams and Microsoft Edge applications to address security threats.
#

# Ensure the script runs as root
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root. Attempting to escalate..."
  exec sudo "$0" "$@"
  exit 1
fi

# Start Execution Timer
START_TIME=$(date +%s)

# Configuration
LOG_FILE="/var/tmp/kandji_edge_remediation.log"
THREAT_VERSION="138.0.3351.83"
SUCCESS_COUNT=0
FAILURE_COUNT=0
FORCE_QUIT=true  # Security requirement: force quit applications

# Threat locations to remediate
declare -a THREAT_LOCATIONS=(
  "/Library/Caches/com.microsoft.autoupdate.helper/Clones.noindex/Microsoft Teams.app/Contents/Helpers/Microsoft Teams WebView.app/Contents/Frameworks/Microsoft Edge Framework.framework"
  "/Applications/Microsoft Teams.app/Contents/Helpers/Microsoft Teams WebView.app/Contents/Frameworks/Microsoft Edge Framework.framework/Versions/${THREAT_VERSION}"
  "/Applications/Microsoft Edge.app/Contents/Frameworks/Microsoft Edge Framework.framework/Versions/${THREAT_VERSION}"
)

# Additional cleanup locations
declare -a CLEANUP_LOCATIONS=(
  "/Library/Caches/com.microsoft.autoupdate.helper/Clones.noindex/Microsoft Teams.app"
  "/Library/Caches/com.microsoft.autoupdate.helper/Clones.noindex/Microsoft Edge.app"
)

# Redirect logs for Kandji
exec > >(tee -a "$LOG_FILE") 2>&1
echo "========================================="
echo "Microsoft Edge Framework Threat Remediation"
echo "Started: $(date)"
echo "Target Version: ${THREAT_VERSION}"
echo "========================================="

# Function: Force quit applications
force_quit_applications() {
  echo ""
  echo "Forcing termination of Microsoft applications for security compliance..."
  
  # Force quit Microsoft Edge and all helpers
  local edge_processes=("Microsoft Edge" "Microsoft Edge Helper" "Microsoft Edge Helper (Renderer)" "Microsoft Edge Helper (GPU)" "Microsoft Edge Helper (Plugin)")
  for process in "${edge_processes[@]}"; do
    if pgrep -x "$process" > /dev/null 2>&1; then
      echo "  - Terminating: $process"
      killall -9 "$process" 2>/dev/null || true
    fi
  done
  
  # Force quit Microsoft Teams and all helpers
  local teams_processes=("Microsoft Teams" "Microsoft Teams Helper" "Microsoft Teams Helper (Renderer)" "Microsoft Teams Helper (GPU)" "Microsoft Teams Helper (Plugin)")
  for process in "${teams_processes[@]}"; do
    if pgrep -x "$process" > /dev/null 2>&1; then
      echo "  - Terminating: $process"
      killall -9 "$process" 2>/dev/null || true
    fi
  done
  
  # Wait for processes to fully terminate
  sleep 2
  
  echo "Application termination complete."
}

# Function: Check if path exists and is a directory
check_path_exists() {
  local path="$1"
  if [[ -d "$path" ]]; then
    return 0
  else
    return 1
  fi
}

# Function: Remove threat location
remove_threat_location() {
  local location="$1"
  
  if check_path_exists "$location"; then
    echo ""
    echo "Found threat location: $location"
    
    # Get size before removal for logging
    local size_kb=$(du -sk "$location" 2>/dev/null | cut -f1)
    echo "  Size: ${size_kb}KB"
    
    # Attempt removal
    if rm -rf "$location" 2>/dev/null; then
      echo "  ✓ Successfully removed threat location"
      ((SUCCESS_COUNT++))
      return 0
    else
      echo "  ✗ Failed to remove threat location (may be in use or protected)"
      ((FAILURE_COUNT++))
      return 1
    fi
  else
    echo "  - Threat location not found (already removed or not present): $location"
    return 2
  fi
}

# Function: Verify framework removal
verify_removal() {
  local all_removed=true
  
  echo ""
  echo "Verifying threat removal..."
  
  for location in "${THREAT_LOCATIONS[@]}"; do
    if check_path_exists "$location"; then
      echo "  ✗ Still exists: $location"
      all_removed=false
    else
      echo "  ✓ Confirmed removed: $location"
    fi
  done
  
  if $all_removed; then
    echo ""
    echo "SUCCESS: All threat locations have been removed."
    return 0
  else
    echo ""
    echo "WARNING: Some threat locations could not be removed."
    return 1
  fi
}

# Function: Clear Microsoft AutoUpdate cache
clear_autoupdate_cache() {
  echo ""
  echo "Clearing Microsoft AutoUpdate cache..."
  
  local cache_dir="/Library/Caches/com.microsoft.autoupdate.helper"
  
  if check_path_exists "$cache_dir"; then
    # Remove the entire Clones.noindex directory
    if rm -rf "$cache_dir/Clones.noindex" 2>/dev/null; then
      echo "  ✓ AutoUpdate cache cleared"
    else
      echo "  ✗ Failed to clear AutoUpdate cache"
    fi
  else
    echo "  - AutoUpdate cache not found"
  fi
}

# Function: Log system information
log_system_info() {
  echo ""
  echo "System Information:"
  echo "  macOS Version: $(sw_vers -productVersion)"
  echo "  Build: $(sw_vers -buildVersion)"
  echo "  Hostname: $(hostname)"
  echo "  Date: $(date)"
  
  # Check installed Microsoft applications
  echo ""
  echo "Installed Microsoft Applications:"
  
  if [[ -d "/Applications/Microsoft Edge.app" ]]; then
    local edge_version=$(defaults read "/Applications/Microsoft Edge.app/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "Unknown")
    echo "  - Microsoft Edge: $edge_version"
  else
    echo "  - Microsoft Edge: Not installed"
  fi
  
  if [[ -d "/Applications/Microsoft Teams.app" ]]; then
    local teams_version=$(defaults read "/Applications/Microsoft Teams.app/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "Unknown")
    echo "  - Microsoft Teams: $teams_version"
  else
    echo "  - Microsoft Teams: Not installed"
  fi
}

# Main execution
main() {
  # Log system information
  log_system_info
  
  # Force quit applications for security compliance
  if $FORCE_QUIT; then
    force_quit_applications
  fi
  
  echo ""
  echo "Beginning threat remediation..."
  echo "========================================="
  
  # Process primary threat locations
  for location in "${THREAT_LOCATIONS[@]}"; do
    remove_threat_location "$location"
  done
  
  # Process cleanup locations
  echo ""
  echo "Performing additional cleanup..."
  for location in "${CLEANUP_LOCATIONS[@]}"; do
    remove_threat_location "$location"
  done
  
  # Clear AutoUpdate cache
  clear_autoupdate_cache
  
  # Verify removal
  verify_removal
  VERIFICATION_RESULT=$?
  
  # Summary
  echo ""
  echo "========================================="
  echo "Remediation Summary:"
  echo "  Successful removals: $SUCCESS_COUNT"
  echo "  Failed removals: $FAILURE_COUNT"
  
  # Calculate execution time
  END_TIME=$(date +%s)
  ELAPSED_TIME=$((END_TIME - START_TIME))
  echo "  Execution time: ${ELAPSED_TIME} seconds"
  echo ""
  
  # Determine exit code
  if [[ $VERIFICATION_RESULT -eq 0 ]]; then
    echo "RESULT: Complete success - all threats remediated"
    echo "Users may now restart Microsoft Edge and Teams. Applications will download updated frameworks automatically."
    echo "========================================="
    echo "Completed: $(date)"
    exit 0
  elif [[ $SUCCESS_COUNT -gt 0 ]]; then
    echo "RESULT: Partial success - some threats remediated"
    echo "Manual intervention may be required for remaining threats."
    echo "========================================="
    echo "Completed: $(date)"
    exit 2
  else
    echo "RESULT: Remediation failed - threats remain"
    echo "Please review the log file at: $LOG_FILE"
    echo "========================================="
    echo "Completed: $(date)"
    exit 1
  fi
}

# Execute main function
main