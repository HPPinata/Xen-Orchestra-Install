#!/bin/bash

defaultSR=$(xe sr-list name-label="Local storage" | grep uuid | awk -F ': ' {'print $2'})
defaultNET=$(xe xe network-list bridge=xenbr0 | grep uuid | awk -F ': ' {'print $2'})

mkdir -p /var/opt/xen/ISO_Store
isoSR=$(xe sr-create name-label=LocalISO type=iso device-config:location=/var/opt/xen/ISO_Store device-config:legacy_mode=true content-type=iso)

vmUID=$(xe vm-install new-name-label=test template-name-label="Other install media")
xe vm-param-set uuid=$vmUID memory-static-max=4294967296 memory-dynamic-max=4294967296 memory-dynamic-min=1073741824 memory-static-min=1073741824

xe vm-disk-add disk-size=32G device=1 uuid=$vmUID
vdiUID=$(xe vm-disk-list uuid=$vmUID | grep -A 1 VDI | grep uuid | awk -F ': ' {'print $2'})

yum install -y qemu-img --enablerepo base
wget https://download.opensuse.org/tumbleweed/appliances/openSUSE-MicroOS.x86_64-kvm-and-xen.qcow2
qemu-img convert -O raw openSUSE-MicroOS.x86_64-kvm-and-xen.qcow2 SUSE-MicroOS.raw
xe vdi-import uuid=$vdiUID filename=test.raw format=raw


wget https://raw.githubusercontent.com/HPPinata/Xen-Orchestra-Install/main/combustion.bash

hashed_password="$(python -c 'import crypt; import getpass; print(crypt.crypt(getpass.getpass()))')"
sed -i "s+HASHchangeME+$hashed_password+g" combustion.bash

mkdir -p disk/combustion
mv combustion.bash disk/combustion/script
yum install -y genisoimage
mkisofs -l -o combustion.iso -V combustion disk

cp combustion.iso /var/opt/xen/ISO_Store
xe sr-scan uuid=$isoSR

xe vm-cd-add cd-name=combustion.iso device=0 uuid=$vmUID

xe vm-start uuid=$vmUID
