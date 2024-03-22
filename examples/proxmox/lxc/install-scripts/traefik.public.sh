#!/usr/bin/env bash

# Start
echo "Init script started: $(date)"

export DEBIAN_FRONTEND=noninteractive

# Download and install traefik
echo "Download and install traefik..."
wget -O /opt/traefik.tar.gz "https://github.com/traefik/traefik/releases/download/v2.10.7/traefik_v2.10.7_linux_amd64.tar.gz"
tar -zxvf /opt/traefik.tar.gz -C /opt
mv /opt/traefik /usr/local/bin
chown root:root /usr/local/bin/traefik
chmod 755 /usr/local/bin/traefik
setcap 'cap_net_bind_service=+ep' /usr/local/bin/traefik # Give the traefik binary the ability to bind to privileged ports (e.g. 80, 443) as a non-root user

# create traefik config
mkdir /etc/traefik
mkdir /etc/traefik/dynamic
cat <<EOF > /etc/traefik/traefik.yml
global:
  checkNewVersion: true
  sendAnonymousUsage: false

log:
  level: DEBUG

entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entryPoint:
          to: websecure
          scheme: https
  websecure:
    address: ":443"
  traefik:
    address: ":8080"

api:
  dashboard: true
  insecure: true

providers:
  file:
    directory: /etc/traefik/dynamic
    watch: true

certificatesResolvers:
  mytlschallenge:
    acme:
      tlsChallenge: true
      email: "deine@example.com"
      storage: "/etc/traefik/acme.json"

serversTransport:
  insecureSkipVerify: true
EOF

# create dynamic config with tcp route and service that passes all requests
cat <<EOF > /etc/traefik/dynamic/watt-secure.yml
tcp:
  routers:
    watt-secure:
      entryPoints:
        - "websecure"
      rule: "HostSNIRegexp(\`{subdomain:[a-zA-Z0-9-]+}.services.example.com\`) || HostSNI(\`media.example.com\`) || HostSNI(\`example.com\`)"
      service: "watt-secure"
      tls:
        passthrough: true
  services:
    watt-secure:
      loadBalancer:
        servers:
          - address: "192.168.1.9:443"
EOF

# create dynamic config for ipwhitelist middleware
cat <<EOF > /etc/traefik/dynamic/ipwl.yml
http:
  middlewares:
    ipwl:
      ipWhiteList:
        sourceRange:
          - "127.0.0.1/32"
          - "172.29.52.0/24"
          - "192.168.1.0/24"
          - "10.8.0.0/24"
EOF

# create dynamic config for traefik dashboard with middleware to block access from outside
cat <<EOF > /etc/traefik/dynamic/dashboard.yml
http:
  routers:
    dashboard:
      entryPoints:
        - "websecure"
      rule: "Host(\`traefik.dev.example.com\`)"
      tls:
        certResolver: "mytlschallenge"
      service: api@internal
      middlewares:
        - ipwl@file
EOF

# write trafik service config
# Inspired by https://gist.github.com/ubergesundheit/7c9d875befc2d7bfd0bf43d8b3862d85
cat <<EOF > /etc/systemd/system/traefik.service
[Unit]
Description=Traefik
After=network-online.target
Wants=network-online.target systemd-networkd-wait-online.service

[Service]
Type=simple
Restart=on-abnormal
; User and group the process will run as.
User=traefik
Group=traefik
; Always set "-root" to something safe in case it gets forgotten in the traefikfile.
ExecStart=/usr/local/bin/traefik --configFile=/etc/traefik/traefik.yml

; Limit the number of file descriptors; see "man systemd.exec" for more limit settings.
LimitNOFILE=1048576
; Use private /tmp and /var/tmp, which are discarded after traefik stops.
PrivateTmp=true
; Use a minimal /dev
PrivateDevices=true
; Hide /home, /root, and /run/user. Nobody will steal your SSH-keys.
ProtectHome=true
; Make /usr, /boot, /etc and possibly some more folders read-only.
ProtectSystem=full
; … except /etc/ssl/traefik, because we want Letsencrypt-certificates there.
;   This merely retains r/w access rights, it does not add any new.
ReadWriteDirectories=/etc/traefik

; The following additional security directives only work with systemd v229 or later.
; They further restrict privileges that can be gained by traefik. Uncomment if you like.
; Note that you may have to add capabilities required by any plugins in use.
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

# create traefik group and user
useradd -r -s /bin/false traefik
chown -R traefik:traefik /etc/traefik
chmod 644 /etc/systemd/system/traefik.service

# enable and start traefik service
systemctl enable traefik
systemctl start traefik
# Test: systemctl status traefik
# Logs: journalctl -u traefik.service -f -n 10
# Boot debug: journalctl --boot -u traefik.service

# Cleanup container
echo "Cleanup..."
rm -rf /opt/*

# End
echo "Init script ended: $(date)"
