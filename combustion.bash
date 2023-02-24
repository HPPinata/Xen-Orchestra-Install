#!/bin/bash
# combustion: network

echo 'root:HASHchangeME' | chpasswd -e
echo 'orchestra' > /etc/hostname
mount /dev/xvda4 /var

mount /dev/sr1 /mnt
zypper rm -yu xen-tools-domU
/mnt/Linux/install.sh -d sles -m 15 -n

echo 'PermitRootLogin yes' > /etc/ssh/sshd_config.d/root.conf

zypper in -y docker-compose wget zram-generator
systemctl enable docker

cat <<'EOL' > /etc/systemd/zram-generator.conf
[zram0]

zram-size = ram
compression-algorithm = zstd
EOL

mkdir -p /var/orchestra
cd /var/orchestra
wget https://raw.githubusercontent.com/HPPinata/Xen-Orchestra-Install/main/compose.yml

cat <<'EOL' > /var/orchestra/update.bash
#!/bin/bash
cd /var/orchestra
docker-compose pull
docker-compose build --pull
docker-compose up -dV
docker system prune -a -f --volumes
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
