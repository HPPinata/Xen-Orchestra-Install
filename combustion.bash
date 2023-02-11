#!/bin/bash
# combustion: network

echo 'root:HASHchangeME' | chpasswd -e
echo 'orchestra' > /etc/hostname
mount /dev/xvda4 /var

mount /dev/sr1 /mnt
zypper rm -yu xen-tools-domU
/mnt/Linux/install.sh -d sles -m 15 -n

zypper in -y wget docker-compose
systemctl enable docker

mkdir -p /var/orchestra
cd /var/orchestra

wget https://raw.githubusercontent.com/HPPinata/Xen-Orchestra-Install/main/compose.yml

cat <<'EOL' > /var/orchestra/update.bash
#!/bin/bash
cd /var/orchestra
systemctl restart docker
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
systemctl enable /etc/systemd/system/orchestra-compose.service
