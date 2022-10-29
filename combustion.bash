#!/bin/bash
# combustion: network
echo 'root:HASHchangeME' | chpasswd -e

zypper --non-interactive install wget docker-compose
systemctl enable --now docker
mount /dev/xvda4 /var


mkdir -p /var/orchestra
cd /var/orchestra
wget https://raw.githubusercontent.com/HPPinata/Xen-Orchestra-Install/main/compose.yml

cat <<'EOL' > /var/orchestra/update.bash
#!/bin/bash
cd /var/orchestra
docker-compose pull
docker-compose build --pull
docker-compose up -dV
EOL
chmod +x /var/orchestra/update.bash

cat <<'EOL' > /etc/systemd/system/orchestra-compose.service
[Unit]
Description=Start Xen-Orchestra Container
After=network-online.target docker.service

[Service]
Type=oneshot
ExecStart=bash -c '/var/orchestra/update.bash'
ExecStop=bash -c '/bin/docker-compose down -f /var/orchestra/compose.yml'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOL
systemctl enable orchestra-compose


mount /dev/sr1 /mnt
tar -xf /mnt/Linux/xe-guest-utilities_*_x86_64.tgz

cat <<'EOL' > /etc/systemd/system/xen-guest-util.service
[Unit]
Description=Start Xen-Guest utilities
After=network-online.target

[Service]
Type=oneshot
ExecStart=bash -c '/etc/init.d/xe-linux-distribution restart'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOL
systemctl enable xen-guest-util
