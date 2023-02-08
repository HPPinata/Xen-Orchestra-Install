#!/bin/bash

yum upgrade -y && yum autoremove -y
mkdir install-tmp
mv createXO.bash install-tmp
cd install-tmp

defaultSR=$(xe sr-list name-label="Local storage" | grep uuid | awk -F ': ' {'print $2'})
defaultNET=$(xe network-list bridge=xenbr0 | grep uuid | awk -F ': ' {'print $2'})


combustion-ISO () {
  mkdir -p /var/opt/xen/ISO_Store
  isoSR=$(xe sr-create name-label=LocalISO type=iso device-config:location=/var/opt/xen/ISO_Store device-config:legacy_mode=true content-type=iso)
  
  wget https://raw.githubusercontent.com/HPPinata/Xen-Orchestra-Install/main/combustion.bash
  
  while [ -z "$hashed_password" ]; do echo "Password previously unset or input inconsistent."; \
    hashed_password="$(python -c 'from __future__ import print_function; import crypt; import getpass; \
    tin = getpass.getpass(); tin2 = getpass.getpass(); print(crypt.crypt(tin)) if (tin == tin2) else ""')"; done
  sed -i "s+HASHchangeME+$hashed_password+g" combustion.bash
  
  mkdir -p disk/combustion
  mv combustion.bash disk/combustion/script
  yum install -y genisoimage
  mkisofs -l -o orchestra_combustion.iso -V combustion disk
  yum remove -y genisoimage && yum autoremove -y
  
  cp orchestra_combustion.iso /var/opt/xen/ISO_Store
  xe sr-scan uuid=$isoSR
}


disk-IMAGE () {
  wget https://download.opensuse.org/tumbleweed/appliances/openSUSE-MicroOS.x86_64-kvm-and-xen.qcow2
  yum install -y qemu-img --enablerepo base
  qemu-img convert -O raw openSUSE-MicroOS.x86_64-kvm-and-xen.qcow2 SUSE-MicroOS.raw
  yum remove -y qemu-img && yum autoremove -y
}


create-VM () {
  vmUID=$(xe vm-install new-name-label=orchestra new-name-description="Xen-Orchestra management VM" template-name-label="Other install media")
  xe vm-memory-limits-set static-min=1GiB static-max=2GiB dynamic-min=1GiB dynamic-max=2GiB uuid=$vmUID
  xe vm-param-set uuid=$vmUID HVM-boot-params:firmware=uefi
  
  xe pool-param-set uuid=$(xe pool-list | grep uuid | awk -F ': ' {'print $2'}) other-config:auto_poweron=true
  xe vm-param-set uuid=$vmUID other-config:auto_poweron=true
  
  xe vif-create network-uuid=$defaultNET vm-uuid=$vmUID device=0
  
  xe vm-disk-add disk-size=24GiB device=0 uuid=$vmUID
  vdiUID=$(xe vm-disk-list uuid=$vmUID | grep -A 1 VDI | grep uuid | awk -F ': ' {'print $2'})
  xe vdi-param-set uuid=$vdiUID name-label=orchestra
  xe vdi-import uuid=$vdiUID filename=SUSE-MicroOS.raw format=raw
  
  xe vm-cd-add cd-name=orchestra_combustion.iso device=1 uuid=$vmUID
  xe vm-cd-add cd-name=guest-tools.iso device=2 uuid=$vmUID
    
  snUID=$(xe vm-snapshot new-name-label=orchestra_preinstall new-name-description="Xen-Orchestra management VM pre install" uuid=$vmUID)
  tpUID=$(xe snapshot-clone new-name-label=MicroOS_Template uuid=$snUID new-name-description="VM Template for an unconfigured MicroOS")
  xe vm-cd-remove cd-name=orchestra_combustion.iso uuid=$tpUID
  xe vm-cd-remove cd-name=guest-tools.iso uuid=$tpUID
}


cleanup () {
  cd .. && rm -rf install-tmp
  
  yum install -y pv --enablerepo epel
  yes | pv -SpeL1 -s 300 > /dev/null
  yum remove -y pv && yum autoremove -y
  
  xe vm-shutdown uuid=$vmUID
  xe vm-cd-remove cd-name=orchestra_combustion.iso uuid=$vmUID
  xe vm-cd-remove cd-name=guest-tools.iso uuid=$vmUID
  xe vm-snapshot new-name-label=orchestra_postinstall new-name-description="Xen-Orchestra management VM post install" uuid=$vmUID
}


combustion-ISO
disk-IMAGE
create-VM

xe vm-start uuid=$vmUID

cleanup
reboot
