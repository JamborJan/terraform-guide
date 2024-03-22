#!/usr/bin/env bash

# Start
echo "Init script started: $(date)"

export DEBIAN_FRONTEND=noninteractive

# Variables
AZDOURL="$1"
AZDOPAT="$2"
AZDOPOL="$3"
AZDOAGT="$4"
AZDOVER="$5"

# Prepare container OS
echo "Setting up container OS..."
sed -i "/$LANG/ s/\(^# \)//" /etc/locale.gen
locale-gen >/dev/null
apt-get autoremove >/dev/null

# Update container OS
echo "Updating container OS..."
apt-get update >/dev/null
apt-get -qqy upgrade &>/dev/null

# Install supporting software
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    git \
    gnupg \
    lsb-release \
    unzip \
    &>/dev/null

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
mkdir -p /etc/apt/keyrings
chmod 0755 /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update >/dev/null
apt-get install -y \
    azure-cli \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin \
    &>/dev/null

# Install dependencies for SonarQube
# Java 17 is required for SonarQube, test with `java -version`
echo "Install dependencies for SonarQube..."
apt-get install -y \
    openjdk-17-jdk \
    shellcheck \
    &>/dev/null

# Install dotnetcore for SonarQube Scanner
echo "Install dotnetcore for SonarQube Scanner..."
wget -q https://packages.microsoft.com/config/debian/11/packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb &>/dev/null
rm packages-microsoft-prod.deb
apt-get update >/dev/null
apt-get install -y \
    dotnet-sdk-7.0 \
    &>/dev/null

# Install Python for Running tests
echo "Install Python..."
apt-get install -y \
    python3 \
    python3-pip \
    &>/dev/null

# Get Azure DevOps Agent
echo "Installing Azure DevOps Agent..."
mkdir -p /opt/agent
wget https://vstsagentpackage.azureedge.net/agent/"$AZDOVER"/vsts-agent-linux-x64-"$AZDOVER".tar.gz &>/dev/null
tar zxvf vsts-agent-linux-x64-"$AZDOVER".tar.gz -C /opt/agent &>/dev/null
rm vsts-agent-linux-x64-"$AZDOVER".tar.gz

# Install agent and service
export AGENT_ALLOW_RUNASROOT="1"
echo "Install dependencies: $(date)"
(cd /opt/agent/bin || return; ./installdependencies.sh)
echo "Agent configuration started: $(date)"
(cd /opt/agent || return; ./config.sh --unattended --url "$AZDOURL" --auth pat --token "$AZDOPAT" --pool "$AZDOPOL" --agent "$AZDOAGT" --replace --acceptTeeEula)
echo "Agent install started: $(date)"
(cd /opt/agent || return; ./svc.sh install)
echo "Try to start agent: $(date)"
(cd /opt/agent || return; ./svc.sh start)

# Setup agent service autostart
cat > /opt/agent-start.sh <<EOF
#!/bin/sh
cd /opt/agent || return
./svc.sh start
EOF

chmod +x /opt/agent-start.sh

line="@reboot /opt/agent-start.sh"
(crontab -u "$(whoami)" -l; echo "$line" ) | crontab -u "$(whoami)" -

# End
echo "Init script ended: $(date)"
