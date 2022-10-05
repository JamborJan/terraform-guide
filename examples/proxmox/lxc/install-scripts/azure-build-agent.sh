#!/bin/sh

# Start
echo "Init script started: $(date)"

# Variables
AZDOURL="https://xwr.visualstudio.com/"
AZDOPAT="2xrxarqlrfgq7c26w3glxqolyzlygqirvmcmbw26koacbgcz63wq"
AZDOPOL="jjspool"
AZDOAGT="DEV-BUILD-01"

# get agent
mkdir -p /opt/agent
wget https://vstsagentpackage.azureedge.net/agent/2.210.0/vsts-agent-linux-x64-2.210.0.tar.gz
tar zxvf vsts-agent-linux-x64-2.210.0.tar.gz -C /opt/agent
rm vsts-agent-linux-x64-2.210.0.tar.gz

# Install agent and service
export AGENT_ALLOW_RUNASROOT="1"
echo "Install dependencies: $(date)"
(cd /opt/agent/bin || return; ./installdependencies.sh)
echo "Agent configuration started: $(date)"
(cd /opt/agent || return; ./config.sh --unattended --url $AZDOURL --auth pat --token $AZDOPAT --pool $AZDOPOL --agent $AZDOAGT --replace --acceptTeeEula)
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
