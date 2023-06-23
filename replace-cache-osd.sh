#!/bin/bash
Deploy_Path=`cd $(dirname $0); pwd -P`
source $Deploy_Path/lib/init_osd_blustore.sh

Cache_Disk_Name=$1
source /var/lib/ceph/osd-mappings/$1





cache_disks_mkparts_for_replace(){

    #获取当前osd数据盘列表
    OSD_Data_Devices=$Data_Disks_Path
    #通过当前缓存盘盘符获取当前缓存盘的disk by-path路径
    Cache_Device_by_path=$Cache_Disk_Path
    #清空缓存盘分区表
    OSD_Device="/dev/$Cache_Disk"
    wipe_osd_device

    #修改设备属主属组为ceph:ceph
    chown -h ceph:ceph $OSD_Device
    #为当前缓存盘创建gpt分区表
    parted -s $Cache_Device_by_path mklabel gpt

    #创建缓存盘分区
    cache_disk_mkparts
}

make_bluestore_osd_for_replace(){

    OSD_Key=`ceph-authtool --gen-print-key`
    OSD_UUID=`uuidgen`

    shell_make_exclusive_bluestore_osd_step

}

replace_osd(){
    make_bluestore_osd_for_replace
}

replace_osd
