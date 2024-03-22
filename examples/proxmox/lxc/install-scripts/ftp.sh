#!/usr/bin/env bash

# Start
echo "Init script started: $(date)"

export DEBIAN_FRONTEND=noninteractive

# Variables
FTP_USER_PASSWORD="$1"

# Check and disable ssh root password authentication if needed
if grep -q "#PermitRootLogin prohibit-password" /etc/ssh/sshd_config; then
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin without-password/g' /etc/ssh/sshd_config
    systemctl restart ssh
    echo "Root password authentication disabled"
fi

# Create ftp user, group and valid home directory if they don't exist
if ! getent group ftpgroup > /dev/null; then
    groupadd ftpgroup
    echo "ftpgroup group created"
fi

if ! id -u ftpuser > /dev/null 2>&1; then
    useradd -g ftpgroup -d /data -s /bin/bash ftpuser
    echo "ftpuser:$FTP_USER_PASSWORD" | chpasswd
    if [ ! -d "/data" ]; then
        mkdir /data
    fi
    chown ftpuser:ftpgroup /data
    chmod 755 /data
    echo "ftpuser user created"
fi

# Install ffmpeg if not already installed
if ! command -v ffmpeg &> /dev/null; then
    apt-get update >/dev/null
    apt-get install -y ffmpeg >/dev/null
    echo "ffmpeg installed"
fi

# Cleanup container
echo "Cleanup..."
apt-get autoremove -y >/dev/null

# End
echo "Init script ended: $(date)"
