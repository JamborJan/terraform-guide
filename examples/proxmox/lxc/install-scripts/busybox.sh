#!/usr/bin/env bash

# Start
echo "Init script started: $(date)"

export DEBIAN_FRONTEND=noninteractive

# Variables
SSH_PUBLIC_KEY_HERE="$1"

# Prepare container OS
echo "Setting up container OS..."
sed -i "/$LANG/ s/\(^# \)//" /etc/locale.gen
locale-gen >/dev/null
apt-get -y purge openssh-{client,server} >/dev/null
apt-get autoremove >/dev/null

# Update container OS
echo "Updating container OS..."
apt-get update >/dev/null
apt-get -qqy upgrade &>/dev/null

# Install supporting software
apt-get install -y \
    apt-transport-https \
    git \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    openssh-server \
    &>/dev/null

# Set up SSH
# Disable root password authentication
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin without-password/g' /etc/ssh/sshd_config
# Create directory for root's SSH configuration if it doesn't exist
mkdir -p /root/.ssh
# Here you need to insert your public key or you can create a new key pair 
# by using the ssh-keygen command, then use the public key here.
echo "$SSH_PUBLIC_KEY_HERE" > /root/.ssh/authorized_keys
# Correct permissions for SSH config files
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys
# Start SSH service
service ssh start

# Add Microsoft repository
echo "Adding Microsoft repository..."
mkdir -p /etc/apt/keyrings
curl -sLS https://packages.microsoft.com/keys/microsoft.asc |
    gpg --dearmor |
    tee /etc/apt/keyrings/microsoft.gpg > /dev/null
chmod go+r /etc/apt/keyrings/microsoft.gpg
AZ_REPO=$(lsb_release -cs)
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" |
    tee /etc/apt/sources.list.d/azure-cli.list

apt-get update >/dev/null
apt-get install -y \
    azure-cli \
    &>/dev/null

# Cleanup container
echo "Cleanup..."
apt-get autoremove >/dev/null

# End
echo "Init script ended: $(date)"
