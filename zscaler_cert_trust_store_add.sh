#!/bin/bash
#
# This script adds the Zscaler Root CA to various system and application-specific trust stores.

# Destination Path of the Zscaler Root CA certificate
# This file is used as a temporary storage for the certificate
CERT_PATH="/tmp/zscaler-root-ca.pem"

# Ensure the certificate exists
if [[ ! -f "$CERT_PATH" ]]; then
    # Extract the Zscaler Root CA certificate from the macOS Keychain
    echo "Extracting Zscaler Root CA certificate..."
    security find-certificate -a -c "Zscaler" -p > "$CERT_PATH"
else
    echo "Certificate already exists. Skipping download."
fi

# Verify certificate existence
if [[ ! -f "$CERT_PATH" ]]; then
    echo "Failed to find or create the certificate. Exiting."
    exit 1
fi

# Function to check if a command or software exists
# @param $1 the command or software to check
function command_exists {
    command -v "$1" >/dev/null 2>&1
}

# Git
# Configure git to trust the Zscaler Root CA
if command_exists git; then
    echo "Configuring Git to trust Zscaler Root CA..."
    git config --global http.sslCAInfo "$CERT_PATH"
else
    echo "Git not detected. Skipping."
fi

# Python (pip and requests)
# Append the Zscaler Root CA to the Python certifi store
# and set the environment variables for SSL_CERT_FILE and REQUESTS_CA_BUNDLE
if command_exists python3; then
    PYTHON_CERTIFI=$(python3 -m certifi 2>/dev/null)
    if [[ -n "$PYTHON_CERTIFI" ]]; then
        echo "Appending Zscaler Root CA to Python certifi store..."
        cat "$CERT_PATH" >> "$PYTHON_CERTIFI"
        export SSL_CERT_FILE="$CERT_PATH"
        export REQUESTS_CA_BUNDLE="$CERT_PATH"
    else
        echo "Python certifi package not detected. Skipping."
    fi
else
    echo "Python not detected. Skipping."
fi

# Docker
# Add the Zscaler Root CA to the Docker certificates
if command_exists docker; then
    echo "Adding Zscaler Root CA to Docker certificates..."
    sudo mkdir -p /etc/docker/certs.d/
    sudo cp "$CERT_PATH" /etc/docker/certs.d/
    sudo update-ca-certificates
else
    echo "Docker not detected. Skipping."
fi

# Node.js (npm)
# Configure npm to trust the Zscaler Root CA
if command_exists npm; then
    echo "Configuring npm to trust Zscaler Root CA..."
    npm config set cafile "$CERT_PATH"
else
    echo "Node.js/npm not detected. Skipping."
fi

# Java (Keytool)
# Add the Zscaler Root CA to the Java trust store
if command_exists keytool; then
    echo "Adding Zscaler Root CA to Java trust store..."
    JAVA_CACERTS=$(find /Library/Java/JavaVirtualMachines -name cacerts | head -n 1)
    if [[ -n "$JAVA_CACERTS" ]]; then
        sudo keytool -importcert -trustcacerts -file "$CERT_PATH" -keystore "$JAVA_CACERTS" -storepass changeit -noprompt
    else
        echo "Java keystore (cacerts) not found. Skipping."
    fi
else
    echo "Java keytool not detected. Skipping."
fi

# Mozilla Firefox
# Add the Zscaler Root CA to Firefox profiles
if [[ -d ~/Library/Application\ Support/Firefox/Profiles ]]; then
    echo "Adding Zscaler Root CA to Firefox profiles..."
    for PROFILE in ~/Library/Application\ Support/Firefox/Profiles/*; do
        certutil -A -n "Zscaler Root CA" -t "TCu,Cu,Tu" -i "$CERT_PATH" -d sql:"$PROFILE"
    done
else
    echo "Firefox profiles not found. Skipping."
fi

# Curl
# Configure Curl to use the Zscaler Root CA
if command_exists curl; then
    echo "Configuring Curl to use Zscaler Root CA..."
    echo "CAINFO=$CERT_PATH" >> ~/.curlrc
else
    echo "Curl not detected. Skipping."
fi

# System-Wide Environment Variables (Optional)
echo "Setting global environment variables for SSL_CERT_FILE, REQUESTS_CA_BUNDLE, and removing temporary file..."
sudo sh -c "echo 'export SSL_CERT_FILE=$CERT_PATH' >> /etc/environment"
sudo sh -c "echo 'export REQUESTS_CA_BUNDLE=$CERT_PATH' >> /etc/environment"
rm -f "$CERT_PATH"

echo "Certificate deployment completed."