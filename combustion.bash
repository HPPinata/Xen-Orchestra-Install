#!/bin/bash
# combustion: network
echo 'root:HASHchangeME' | chpasswd -e

zypper --non-interactive install wget docker-compose lsb-release
systemctl enable docker

mount /dev/xvdb4 /var

mount /dev/sr1 /mnt
zypper rm -yu xen-tools-domU
zypper in -y --allow-unsigned-rpm /mnt/Linux/*.x86_64.rpm

cp -f /mnt/Linux/xen-vcpu-hotplug.rules /etc/udev/rules.d/
cp -f /mnt/Linux/xe-linux-distribution.service /etc/systemd/system/
sed -i 's+share/oem/xs+sbin+g' /etc/systemd/system/xe-linux-distribution.service
sed -i 's+ /var/cache/xe-linux-distribution++g' /etc/systemd/system/xe-linux-distribution.service
systemctl daemon-reload
systemctl enable /etc/systemd/system/xe-linux-distribution

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
