#!/bin/bash
# combustion: network

echo 'root:HASHchangeME' | chpasswd -e

zypper --non-interactive install wget docker-compose
systemctl enable docker
mount /dev/xvda4 /var


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


mount /dev/sr1 /mnt
zypper rm -yu xen-tools-domU
zypper in -y lsb-release
zypper in -y --allow-unsigned-rpm /mnt/Linux/*.x86_64.rpm
pkill -f "xe-daemon"

cp -f /mnt/Linux/xen-vcpu-hotplug.rules /etc/udev/rules.d/
cp -f /mnt/Linux/xe-linux-distribution.service /etc/systemd/system/
sed -i 's+share/oem/xs+sbin+g' /etc/systemd/system/xe-linux-distribution.service
sed -i 's+ /var/cache/xe-linux-distribution++g' /etc/systemd/system/xe-linux-distribution.service
systemctl enable /etc/systemd/system/xe-linux-distribution.service
