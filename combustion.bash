#!/bin/bash

echo 'root:HASHchangeME' | chpasswd -e

zypper --non-interactive install podman docker-compose

systemctl disable docker
systemctl enable podman
systemctl enable sshd.service

mount /dev/xvdb4 /var

mkdir -p /var/orchestra
cd /var/orchestra
wget https://raw.githubusercontent.com/HPPinata/Xen-Orchestra-Install/compose.yml

cat <<'EOL' > /var/orchestra/update.bash
#!/bin/bash
docker-compose down
docker-compose pull
docker-compose build --pull
docker-compose up -dV
EOL
chmod +x /var/orchestra/update.bash

cat <<'EOL' > /etc/systemd/system/orchestra-compose.service
[Unit]
Description=Start Xen-Orchestra Container
After=network-online.target

[Service]
Type=oneshot
ExecStart=/var/orchestra/update.bash
ExecStop=/bin/docker-compose down -f /var/orchestra/compose.yml
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target

systemctl enable orchestra-compose
