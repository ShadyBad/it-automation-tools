#!/bin/bash
#
# This script is used to configure SSL inspection on macOS for use with Zscaler.
# It extracts the Zscaler certificate from the system keychain and configures
# various command-line tools to trust the certificate.
#
# The script is intended to be run as root and will escalate privileges if necessary.

# Ensure the script runs as root
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root. Attempting to escalate..."
  exec sudo "$0" "$@"
  exit 1
fi

# Set HOME for correct execution (fixes Git and other tools)
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
GCP_CAFILE="$HOME/.config/gcloud/custom-ca-cert.crt"
RUST_CONFIG="$HOME/.cargo/config"
SF_CA_ENV="NODE_EXTRA_CA_CERTS"
COMPOSER_CA_ENV="COMPOSER_CAFILE"
RUBY_SSL_ENV="SSL_CERT_FILE"

# Ensure writable directories exist
mkdir -p "$BACKUP_DIR"
mkdir -p "$(dirname "$CURL_CA_BUNDLE")"
mkdir -p "$(dirname "$GCP_CAFILE")"
mkdir -p "$(dirname "$RUST_CONFIG")"

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

### Configure Google Cloud SDK
if command -v gcloud &>/dev/null; then
  echo "Configuring Google Cloud SDK SSL settings..."
  backup_config_file "$GCP_CAFILE"
  cp "$CERT_PATH" "$GCP_CAFILE"
  gcloud config set core/custom_ca_certs_file "$GCP_CAFILE"
  echo "Google Cloud SDK now trusts the Zscaler certificate."
else
  echo "Google Cloud SDK is not installed. Skipping configuration."
fi

### Configure Rust (Cargo)
if command -v cargo &>/dev/null; then
  echo "Configuring Rust (Cargo) SSL settings..."
  backup_config_file "$RUST_CONFIG"
  append_if_missing "$RUST_CONFIG" "[http]"
  append_if_missing "$RUST_CONFIG" "cainfo = \"$CURL_CA_BUNDLE\""
  echo "Rust (Cargo) now trusts the Zscaler certificate."
else
  echo "Rust (Cargo) is not installed. Skipping configuration."
fi

### Configure Salesforce CLI
if command -v sf &>/dev/null || command -v sfdx &>/dev/null; then
  echo "Configuring Salesforce CLI SSL settings..."
  export $SF_CA_ENV="$CURL_CA_BUNDLE"
  append_if_missing "$HOME/.zshrc" "export $SF_CA_ENV=$CURL_CA_BUNDLE"
  echo "Salesforce CLI now trusts the Zscaler certificate."
else
  echo "Salesforce CLI is not installed. Skipping configuration."
fi

### Configure Composer (PHP)
if command -v composer &>/dev/null; then
  echo "Configuring Composer SSL settings..."
  export $COMPOSER_CA_ENV="$CURL_CA_BUNDLE"
  append_if_missing "$HOME/.zshrc" "export $COMPOSER_CA_ENV=$CURL_CA_BUNDLE"
  echo "Composer now trusts the Zscaler certificate."
else
  echo "Composer (PHP) is not installed. Skipping configuration."
fi

### Configure Ruby
if command -v ruby &>/dev/null; then
  echo "Configuring Ruby SSL settings..."
  export $RUBY_SSL_ENV="$CURL_CA_BUNDLE"
  append_if_missing "$HOME/.zshrc" "export $RUBY_SSL_ENV=$CURL_CA_BUNDLE"
  echo "Ruby now trusts the Zscaler certificate."
else
  echo "Ruby is not installed. Skipping configuration."
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

echo "SSL Inspection config complete."