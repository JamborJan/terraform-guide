#!/usr/bin/env bash

echo "Starting the setup script: $(date)"

export DEBIAN_FRONTEND=noninteractive

# Get Debian version
DEBIAN_VERSION=$(cat /etc/os-release | grep VERSION_CODENAME | cut -d "=" -f 2)

# Add non-free and contrib repositories
echo "Adding non-free and contrib repositories..."
truncate -s 0 /etc/apt/sources.list
echo "deb http://deb.debian.org/debian $DEBIAN_VERSION main contrib non-free" | tee -a /etc/apt/sources.list > /dev/null
echo "deb http://deb.debian.org/debian $DEBIAN_VERSION-updates main contrib non-free" | tee -a /etc/apt/sources.list > /dev/null
echo "deb http://deb.debian.org/debian $DEBIAN_VERSION-backports main contrib non-free" | tee -a /etc/apt/sources.list > /dev/null
echo "deb http://security.debian.org/debian-security/ $DEBIAN_VERSION-security main contrib non-free" | tee -a /etc/apt/sources.list > /dev/null

# Update the OS
echo "Updating the OS..."
apt-get update
apt-get -y upgrade

# Install RTL-SDR and other tools
echo "Install RTL-SDR..."
apt-get install -y \
    rtl-sdr \
    usbutils \
    openssh-server \
    wget \
    &>/dev/null

# Blacklist the DVB-T drivers to prevent them from attaching to the stick
echo "Blacklisting the DVB-T drivers..."
echo 'blacklist dvb_usb_rtl28xxu' > /etc/modprobe.d/blacklist-dvb_usb_rtl28xxu.conf

# Add user to dialout group for permission to access USB device
echo "Adding user to dialout group..."
usermod -a -G dialout root

# Cleanup
echo "Cleanup..."
apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "Setup script finished: $(date)"
