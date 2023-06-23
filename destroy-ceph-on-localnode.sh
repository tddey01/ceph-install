#!/bin/bash
Deploy_Path=`cd $(dirname $0);pwd -P`
source $Deploy_Path/ceph_cluster.env

rm -f $Deploy_Path/logs/*
systemctl stop ceph* 
systemctl stop ceph-mon@`hostname` ceph-mds@`hostname` ceph-mgr@`hostname`
systemctl disable ceph-mon@`hostname` ceph-mds@`hostname` ceph-mgr@`hostname`
systemctl disable ceph* 
systemctl stop pmcd pmlogger pmie
systemctl disable pmcd pmlogger pmie
CEPH_PROC=$(ps -aux|grep ceph|grep -v grep|grep -v destroy |awk '{print $2}')
for i in $CEPH_PROC;do
    kill -9 $i
done
sleep 12
mounts=`mount |grep ceph|awk '{print $3}'`
for i in $mounts;do
    umount $i
done

osds=`ls /var/lib/ceph/osd-mapping/|grep -v cache|awk -F '.' '{print $NF}'`
for i in $osds;do
    systemctl stop var-lib-ceph-osd-ceph\\x2d$i.mount
    systemctl disable var-lib-ceph-osd-ceph\\x2d$i.mount
done

mount_units=`ls /usr/lib/systemd/system/|grep mount|grep var-lib-ceph-osd`
for i in $mount_units;do
    rm -f /usr/lib/systemd/system/$i
done

rm -rf /etc/ceph/* ;rm -rf /var/lib/ceph/mon/* ;rm -rf /var/lib/ceph/mgr/* ;rm -rf /var/lib/ceph/mds/* ;rm -rf /var/lib/ceph/tmp/* ;rm -rf /var/log/ceph/* ;rm -rf /var/lib/ceph/osd-mapping
rm -rf /var/lib/ceph/osd/*

systemctl daemon-reload

#BCache_Map_Devices=`ls -l /dev/bcache/by-uuid/|grep bcache|awk -F'/' '{print $NF}'`
#BCache_Devices=`ls -l /sys/fs/bcache/|egrep ^d|awk '{print $NF}'` 

#for i in $BCache_Devices;do
    #BCache_UUID=`ls -l /dev/bcache/by-uuid/|grep -w $i|awk '{print $9}'`
#    BCache_UUID=$i
#    BCache_Dev=`ls -l /sys/fs/bcache/$BCache_UUID/|grep block|grep devices|egrep ^l|awk -F'/' '{print $(NF-1)}'`
    #echo 1 > /sys/fs/bcache/$BCache_UUID/stop
#    echo 1 > /sys/fs/bcache/$BCache_UUID/unregister
#    echo 1 > /sys/block/$BCache_Dev/bcache/stop
#done

BCache_UUID=`ls /sys/fs/bcache/ |sed -n '/.*-.*-.*-.*-.*/p'`
for i in $BCache_UUID;do
    echo 1 > /sys/fs/bcache/$i/unregister
    echo 1 > /sys/fs/bcache/$i/stop
done
sleep 5

Block_BCaches=`ls /sys/block/ |grep bcache`
for i in $Block_BCaches;do
    echo echo 1 > /sys/block/$i/bcache/stop
done
sleep 5

for i in $BCache_UUID;do
    BCache_Dev=`ls -l /sys/fs/bcache/$BCache_UUID/|grep block|grep devices|egrep ^l|awk -F'/' '{print $(NF-1)}'`
    if [ -z $BCache_Dev ];then
        dd if=/dev/zero of=/dev/$BCache_Dev bs=4M count=1 && sync
    else
        echo 'BCache_Dev is null'
    fi
done


Parts=`lsblk -l|grep part|sed -n '/part *$/p'|awk '{print $1}'`
  #Disks=`echo $Parts|sed -n 's/[0-9]\+$//p'|sort -u`
root_disk=`lsblk -l|sed -n '/\/$/p'|awk '{print $1}'|sed -n 's/[0-9]\+//p'`
Disks=`lsblk -l|grep disk|awk '{print $1}'|grep -v "$root_disk"`
for d in $Disks;do

echo $Parts|grep "$d"
    if [ "$?"x == "0"x ];then
        Disk_Parts=`echo $Parts|grep $d`
        for p in $Disk_Parts;do
	    echo 1 > /sys/block/$d/$p/bcache/unregister
            echo 1 > /sys/block/$d/$p/bcache/stop
	    lsblk -l|grep part|sed -n '/part *$/p'|awk '{print $1}' |grep -w $p
	    if [ "$?" == "0" ];then
	    dd if=/dev/zero of=/dev/$p bs=4M count=1 && sync
	    fi
        done
    
fi

        echo 1 > /sys/block/$d/bcache/unregister
	echo 1 > /sys/block/$d/bcache/stop

        dd if=/dev/zero of=/dev/$d bs=8M count=1 && sync
        partprobe /dev/$d
done


chown -R root:root /dev/
sync & wait
#reboot
