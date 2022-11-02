# Xen-Orchestra-Install

This script was created to spin up a working instance of Xen-Orchestra (community edition) from a newly installed XCP-ng server cli easily.
It creates a VM to run openSUSE MicroOS + docker-compose to use [this image](https://hub.docker.com/r/ezka77/xen-orchestra-ce).

## Usage:
```
yum update -y && yum autoremove -y && reboot #update and reboot to get the correct guest-util ISO version
wget https://raw.githubusercontent.com/HPPinata/Xen-Orchestra-Install/main/createVM.bash
cat createVM.bash #look at the things you download
bash createVM.bash
```

After the script completes the host reboots, then the Xen-Orchestra interface should be reachable on the IP address
your DHCP server assigned to the VM on port 5050. The default credentials are admin@admin.net with password admin.

## Design choices:

My main goals were to give a starting point for easy customisation (not just a baked vhd file) and have the OS be as manitenance free as possible.

I originally considered Fedora CoreOS, but it requires either a hypervisor backchannel, the coreos-installer package (or a working container environment)
to put the configuration file into the install ISO. (I really tried to do it with standard tools; unpack-repack with genisoimage, in place update with xorriso,
even hexdump and dd, but the ISO either would not boot or did not pick up the [butane -> ignition -> cpio newc -> xz + padding] config image correctly).

So i went with Opensuse MicroOS instead which allows one to just attatch the configuration (which can even be written in plain bash) as a separate ISO.
The guest-utils are installed from the XCP-ng ISO as the openSUSE ones (xen-tools-domU) don't work with XCP-ng.
