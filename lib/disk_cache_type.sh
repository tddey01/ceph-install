#!/bin/bash

disks=$(lsscsi|grep disk|awk '{print $1, $NF}'|sed -n 's/\[//g;s/\]//g;s#/dev/##g;s/\ /-/gp')
for i in $disks;do
    disk_slot=`echo $i|awk -F'-' '{print $1}'`
    echo 'write through' > /sys/block/$i/queue/write_cache
    echo 'write through' > /sys/block/$i/device/scsi_disk/$disk_slot/cache_type
done

