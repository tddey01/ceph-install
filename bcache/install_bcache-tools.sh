#!/bin/bash
script_path=`cd $(dirname $0);pwd -P`

#modprobe -f bcache
mkdir -p /usr/share/initramfs-tools/hooks/
mkdir -p /usr/lib/initcpio/install/
mkdir -p /lib/dracut/modules.d/90bcache/

echo "#！/bin/sh" > /etc/sysconfig/modules/bcache.modules
echo "/sbin/depmod -A" >> /etc/sysconfig/modules/bcache.modules
echo "/sbin/modprobe -f bcache" >> /etc/sysconfig/modules/bcache.modules
chmod 755 /etc/sysconfig/modules/bcache.modules


cp -f $script_path/make-bcache /usr/sbin/make-bcache && chmod 755 /usr/sbin/make-bcache
cp -f $script_path/bcache-super-show /usr/sbin/bcache-super-show && chmod 755 /usr/sbin/bcache-super-show
cp -f $script_path/probe-bcache /lib/udev/probe-bcache && chmod 755 /lib/udev/probe-bcache
cp -f $script_path/bcache-register /lib/udev/bcache-register && chmod 755 /lib/udev/bcache-register
cp -f $script_path/69-bcache.rules /lib/udev/rules.d/69-bcache.rules  && chmod 644 /lib/udev/rules.d/69-bcache.rules
cp -f $script_path/hook /usr/share/initramfs-tools/hooks/bcache && chmod 755 /usr/share/initramfs-tools/hooks/bcache
cp -f $script_path/install /usr/lib/initcpio/install/bcache && chmod 755 /usr/lib/initcpio/install/bcache
cp -f $script_path/module-setup.sh /lib/dracut/modules.d/90bcache/module-setup.sh && chmod 755 /lib/dracut/modules.d/90bcache/module-setup.sh
