#!/bin/bash

wget https://raw.githubusercontent.com/HPPinata/Xen-Orchestra-Install/main/combustion.bash

hashed_password="$(python -c 'import crypt; import getpass; print(crypt.crypt(getpass.getpass()))')"
sed -i "s+HASHchangeME+$hashed_password+g" combustion.bash

mkdir -p disk/combustion
mv combustion.bash disk/combustion/script
mkisofs -o combustion.iso -V combustion disk
