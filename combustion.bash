#!/bin/bash
# combustion: network

echo 'root:HASHchangeME' | chpasswd -e
useradd admin
echo 'admin:HASHchangeME' | chpasswd -e
echo 'orchestra' > /etc/hostname

growpart /dev/vda 3
btrfs filesystem resize max /
mount -o subvol=@/var /dev/xvda3 /var
mount /dev/sr1 /mnt

zypper rm -yu xen-tools-domU
/mnt/Linux/install.sh -d sles -m 15 -n

zypper in -y cron curl docker-compose zram-generator
systemctl enable docker

cat <<'EOL' > /etc/systemd/zram-generator.conf
[zram0]

zram-size = ram
compression-algorithm = zstd
EOL

sed -i "s+SELINUX=enforcing+SELINUX=permissive+g" /etc/selinux/config

mkdir /var/orchestra
cd /var/orchestra
curl -O https://raw.githubusercontent.com/HPPinata/Xen-Orchestra-Install/main/compose.yml

cat <<'EOL' > /var/orchestra/update.bash
#!/bin/bash
cd /var/orchestra
docker compose pull
docker compose build --pull
docker compose up -dV
docker system prune -a -f --volumes
EOL
chmod +x /var/orchestra/update.bash

cat <<'EOL' | crontab -
SHELL=/bin/bash
BASH_ENV=/etc/profile
@reboot /var/orchestra/update.bash
EOL
