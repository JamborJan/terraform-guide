#!/usr/bin/env bash

# Start
echo "Init script started: $(date)"

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
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    &>/dev/null

# Customize Docker configuration
echo "Customizing Docker..."
DOCKER_CONFIG_PATH='/etc/docker/daemon.json'
mkdir -p "$(dirname $DOCKER_CONFIG_PATH)"
cat >$DOCKER_CONFIG_PATH <<'EOF'
{
  "log-driver": "journald"
}
EOF

# Install Docker
echo "Install Docker..."
mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update >/dev/null
apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin \
    &>/dev/null

# Install Portainer
echo "Installing Portainer..."
docker volume create portainer_data >/dev/null
docker run -d \
  -p 8000:8000 \
  -p 9000:9000 \
  --label com.centurylinklabs.watchtower.enable=true \
  --name=portainer \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ee &>/dev/null

# Install Watchtower
echo "Installing Watchtower..."
docker run -d \
  --name watchtower \
  -v /var/run/docker.sock:/var/run/docker.sock \
  containrrr/watchtower \
  --cleanup \
  --label-enable &>/dev/null

# Customize container
echo "Customizing container..."
rm /etc/motd # Remove message of the day after login
rm /etc/update-motd.d/10-uname # Remove kernel information after login
touch ~/.hushlogin # Remove 'Last login: ' and mail notification after login
GETTY_OVERRIDE="/etc/systemd/system/container-getty@1.service.d/override.conf"
mkdir -p "$(dirname $GETTY_OVERRIDE)"
cat << EOF > $GETTY_OVERRIDE
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear --keep-baud tty%I 115200,38400,9600 \$TERM
EOF
systemctl daemon-reload
systemctl restart "$(basename "$(dirname $GETTY_OVERRIDE)" | sed 's/\.d//')"

# Cleanup container
echo "Cleanup..."
rm -rf /setup.sh /var/{cache,log}/* /var/lib/apt/lists/*

# End
echo "Init script ended: $(date)"
