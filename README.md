# Xen-Orchestra-Install

This script was created to get a working instance of Xen-Orchestra (community edition) from a newly installed XCP-ng server completely automatically.
It creates a VM to run openSUSE MicroOS + docker-compose to use [this image](https://hub.docker.com/r/ezka77/xen-orchestra-ce).

## Usage:
```
yum update -y && yum autoremove -y && reboot #update and reboot to get the correct guest-util ISO version
wget https://raw.githubusercontent.com/HPPinata/Xen-Orchestra-Install/main/createVM.bash
cat createVM.bash #look at the things you download
bash createVM.bash
```

Around 2-3 minutes after the script completes the Xen-Orchestra interface should be reachable on the IP address your DHCP server assigned to the VM on port 5050.
The default credentials are admin@admin.net with password admin. I recommend you to enable autostart for this VM and eject the ISOs
(so autostart still works for this VM if the tools are updated to a new version on the host later on).

## Design choices:

My main goals were to give a starting point for easy customisation (not just a baked vhd file) and have the OS be as manitenance free as possible.

I originally considered Fedora CoreOS, but it requires either a hypervisor backchannel, the coreos-installer package (or a working container environment)
to put the configuration file into the install ISO. (I really tried to do it with standard tools; unpack-repack with genisoimage, in place update with xorriso,
even hexdump and dd, but the ISO either would not boot or did not pick up the [butane -> ignition -> cpio newc -> xz + padding] image correctly).

So instead i went with Opensuse MicroOS which allows one to just attatch the configuration (which can even be written in plain bash) as a separate ISO.
The guest-utils are installed from the XCP-ng ISO as the openSUSE ones don't get picked up correctly.
