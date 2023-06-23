#!/bin/bash

cache_disk_name=$1
host_osds=`ls /etc/systemd/system/ceph-osd.target.wants/|awk -F'@' '{print $2}'|awk -F'.' '{print $1}'`
source /var/lib/ceph/osd-mappings/$cache_disk_name

remove_sigle_osd(){
    ceph osd out $OSD_ID && sleep 1
    ceph osd down $OSD_ID && sleep 1
    systemctl stop ceph-osd@$OSD_ID && sleep 1
    systemctl disable ceph-osd@$OSD_ID && sleep 1
    ceph osd crush remove $OSD_ID && sleep 1
    ceph auth del $OSD_ID && sleep 1
    ceph osd rm $OSD_ID && sleep 1
    ceph osd tree
    ceph -s
    sleep 20s
}

remove_all_osd(){
   for i in $osds;do
       remove_sigle_osd $i
   done
}

unmount_osd_work_dir(){
    lsof /var/lib/ceph/osd/ceph-$OSD_ID
    osd_files=`ls /var/lib/ceph/osd/ceph-$OSD_ID/`
    for osd_file in $osd_files;do
        if lsof /var/lib/ceph/osd/ceph-$OSD_ID/$osd_file;then
            echo "/var/lib/ceph/osd/ceph-$OSD_ID/$osd_file is busy!"
            exit 1
        fi
    done
    umount -f /var/lib/ceph/osd/ceph-$OSD_ID
}


unbind_bcache(){
    lsof /dev/$BCache_Device
    lsof /dev/$Bcache_Part
    lsof /dev/$Data_Disk

    Bcache_C_Set_UUID=`bcache-super-show /dev/$Bcache_Part |grep -w 'cset.uuid'|awk '{print $NF}'`
    Bcache_B_Set_UUID=`bcache-super-show /dev/$Data_Disk |grep -w 'cset.uuid'|awk '{print $NF}'`
    if [ -z "$Bcache_C_Set_UUID" && -z "$Bcache_B_Set_UUID" && "$Bcache_C_Set_UUID"x == "$Bcache_B_Set_UUID"x ];then
        echo 1 > /sys/fs/bcache/$Bcache_C_Set_UUID/unregister
        sleep 5s
        echo 1 > /sys/fs/bcache/$Bcache_C_Set_UUID/stop
        sleep 5s
        echo "The bcache device $BCache_Device stop success!"
    else
        echo "The Bcache_C_Set_UUID:$Bcache_C_Set_UUID and Bcache_B_Set_UUID:$Bcache_B_Set_UUID are inconsistent or there is a variable whose value is empty!"
    fi
}


destroy_bcache_part(){
    dd if=/dev/zero of=/dev/$Bcache_Part bs=4m count=1  && sync
    ls -l /dev/$BCache_Device
    partprobe & wait
}

destroy_block_wal_part(){
    dd if=/dev/zero of=/dev/$_Part bs=4m count=1  && sync
    ls -l /dev/$BCache_Device
    partprobe & wait
}

destroy_block_db_part(){
    dd if=/dev/zero of=/dev/$_Part bs=4m count=1  && sync
    ls -l /dev/$BCache_Device
    partprobe & wait
}

start_remove(){
    for i in host_osds;do
        echo "host osd $i == OSD_ID $OSD_ID"
        if [ "$i"x == "$OSD_ID"x ];then
            remove_osd
            umount_osd_work_dir
            unbind_bcache
            destroy_bcache_part
            #destroy_block_db_part
            #destroy_block_wal_part
        fi
    done
}

start_remove
