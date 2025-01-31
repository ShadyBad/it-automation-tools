#!/bin/bash
#
# This script is used to configure SSL inspection on macOS for use with Zscaler.
# It extracts the Zscaler certificate from the system keychain, and configures
# various command-line tools to trust the certificate.
#
# The script is intended to be run as root, and will escalate privileges if necessary.

# Ensure the script runs as root
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root. Attempting to escalate..."
  exec sudo "$0" "$@"
  exit 1
fi

# Set HOME for correct Git execution
export HOME="/var/root"

# Start Execution Timer
START_TIME=$(date +%s)

# Configuration
CERT_NAME="Zscaler Root CA"
CERT_PATH="/var/tmp/zscaler-cert.crt"
LOG_FILE="/var/tmp/kandji_zscaler_ssl.log"

# Certificate trust locations
BACKUP_DIR="/var/tmp/ssl_config_backup"
DOCKER_CERT_PATH="/etc/ssl/certs"
DOCKER_CERT_FILE="$DOCKER_CERT_PATH/zscaler.crt"
NPM_CAFILE="/etc/ssl/cert.pem"
PIP_CONF_PATH="$HOME/.pip/pip.conf"
CURL_CA_BUNDLE="$HOME/.ssl_certs/zscaler-ca.crt"
GIT_SSL_CERT_PATH="/usr/local/share/ca-certificates"
SNOWFLAKE_ODBC_CERT_PATH="/usr/local/share/ca-certificates"

# Ensure writable directories exist
mkdir -p "$BACKUP_DIR"
mkdir -p "$(dirname "$CURL_CA_BUNDLE")"

# Redirect logs for Kandji
exec > >(tee -a "$LOG_FILE") 2>&1
echo "Starting Kandji Zscaler SSL configuration..."

# macOS version check
OS_VERSION=$(sw_vers -productVersion)
if [[ "$OS_VERSION" < "10.15" ]]; then
  echo "WARNING: This script is optimized for macOS 10.15+." >> "$LOG_FILE"
fi

# Internet connectivity check
if ! ping -c 2 8.8.8.8 &> /dev/null; then
  echo "ERROR: No internet connection detected. Exiting." >> "$LOG_FILE"
  exit 1
fi

### Function: Extract Zscaler Certificate
extract_certificate_from_keychain() {
  echo "Extracting Zscaler certificate from Keychain..."
  security find-certificate -c "$CERT_NAME" -p /Library/Keychains/System.keychain > "$CERT_PATH" || {
    echo "ERROR: Failed to extract Zscaler certificate." >> "$LOG_FILE"
    exit 1
  }
}

### Function: Backup Configuration File
backup_config_file() {
  local file=$1
  if [[ -f "$file" ]]; then
    echo "Backing up existing configuration file: $file"
    cp "$file" "$BACKUP_DIR/$(basename "$file").bak"
  fi
}

### Function: Append Setting If Not Already Present
append_if_missing() {
  local file=$1
  local entry=$2
  if grep -qxF "$entry" "$file" 2>/dev/null; then
    echo "No changes needed for $file (already contains: $entry)"
  else
    echo "Modifying $file - Adding: $entry"
    echo "$entry" >> "$file"
  fi
}

# Extract Certificate if it exists
if security find-certificate -c "$CERT_NAME" &>/dev/null; then
  extract_certificate_from_keychain
else
  echo "ERROR: Zscaler certificate not found in Keychain. Ensure it is installed before running this script."
  exit 1
fi

### Configure NPM
if command -v npm &>/dev/null; then
  echo "Configuring NPM SSL settings..."
  backup_config_file "$HOME/.npmrc"
  append_if_missing "$HOME/.npmrc" "cafile=$NPM_CAFILE"
else
  echo "NPM is not installed. Skipping configuration."
fi

### Configure PIP
if command -v pip &>/dev/null; then
  echo "Configuring PIP SSL settings..."
  mkdir -p ~/.pip
  backup_config_file "$PIP_CONF_PATH"
  append_if_missing "$PIP_CONF_PATH" "[global]"
  append_if_missing "$PIP_CONF_PATH" "cert = $NPM_CAFILE"
else
  echo "PIP is not installed. Skipping configuration."
fi

### Configure Docker
if command -v docker &>/dev/null; then
  if [[ -f "$DOCKER_CERT_FILE" ]]; then
    echo "Docker SSL certificate is already configured."
  else
    echo "Configuring Docker SSL settings..."
    mkdir -p "$DOCKER_CERT_PATH"
    cp "$CERT_PATH" "$DOCKER_CERT_FILE"
    chmod 644 "$DOCKER_CERT_FILE"
    echo "Docker now trusts the Zscaler certificate."
  fi
else
  echo "Docker is not installed. Skipping configuration."
fi

### Configure cURL (Per-User Certificate)
if command -v curl &>/dev/null; then
  echo "Configuring cURL SSL settings..."
  cp "$CERT_PATH" "$CURL_CA_BUNDLE"

  # Ensure .zshrc is modified in the correct location
  ZSHRC_FILE="$HOME/.zshrc"
  append_if_missing "$ZSHRC_FILE" "export CURL_CA_BUNDLE=$CURL_CA_BUNDLE"

  echo "cURL is now using a custom CA bundle for SSL trust."
else
  echo "cURL is not installed. Skipping configuration."
fi

### Configure Git
if command -v git &>/dev/null; then
  if git config --global --get http.sslCAinfo | grep -q "$GIT_SSL_CERT_PATH"; then
    echo "Git SSL certificate is already configured."
  else
    echo "Configuring Git SSL settings..."
    cp "$CERT_PATH" "$GIT_SSL_CERT_PATH"
    git config --global http.sslCAinfo "$GIT_SSL_CERT_PATH/$(basename "$CERT_PATH")"
    echo "Git now trusts the Zscaler certificate."
  fi
else
  echo "Git is not installed. Skipping configuration."
fi

### Configure Snowflake ODBC
if [[ -d "$SNOWFLAKE_ODBC_CERT_PATH" ]]; then
  if [[ -f "$SNOWFLAKE_ODBC_CERT_PATH/zscaler.crt" ]]; then
    echo "Snowflake ODBC SSL certificate is already configured."
  else
    echo "Configuring Snowflake ODBC SSL settings..."
    cp "$CERT_PATH" "$SNOWFLAKE_ODBC_CERT_PATH"
    echo "Snowflake ODBC now trusts the Zscaler certificate."
  fi
else
  echo "Snowflake ODBC Driver is not installed. Skipping configuration."
fi

### Cleanup Temporary Files
if [[ -f "$CERT_PATH" ]]; then
  echo "Cleaning up temporary certificate file..."
  rm -f "$CERT_PATH"
fi

# End Execution Timer and Log Duration
END_TIME=$(date +%s)
ELAPSED_TIME=$((END_TIME - START_TIME))
echo "Script completed in $ELAPSED_TIME seconds." >> "$LOG_FILE"

echo "SSL Inspection configuration complete."
