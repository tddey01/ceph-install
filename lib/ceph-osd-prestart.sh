#!/bin/sh

if [ `uname` = FreeBSD ]; then
  GETOPT=/usr/local/bin/getopt
else
  GETOPT=getopt
fi

eval set -- "$(${GETOPT} -o i: --long id:,cluster: -- $@)"

while true ; do
	case "$1" in
		-i|--id) id=$2; shift 2 ;;
		--cluster) cluster=$2; shift 2 ;;
		--) shift ; break ;;
	esac
done

if [ -z "$id"  ]; then
    echo "Usage: $0 [OPTIONS]"
    echo "--id/-i ID        set ID portion of my name"
    echo "--cluster NAME    set cluster name (default: ceph)"
    exit 1;
fi

BCache_Device_UUID=`bcache-super-show $Data_Disk_Path|grep -w 'dev.uuid'|awk '{print $NF}'`
BCache_Device_by_uuid=/dev/bcache/by-uuid/$BCache_Device_UUID
BCache_Device=`ls -l /dev/bcache/by-uuid/$BCache_Device_UUID|awk -F '/' '{print $NF}'`
Block_DB_Part=`ls -l $Block_DB_Part_Path |awk -F '/' '{print $NF}'`
Cache_Disk=`ls -l $Cache_Disk_Path |awk -F '/' '{print $NF}'`
Data_Disk=`ls -l $Data_Disk_Path |awk -F '/' '{print $NF}'`
Block_BCache_Part=`ls -l $Block_BCache_Part_Path |awk -F '/' '{print $NF}'`
Block_WAL_Part=`ls -l $Block_WAL_Part_Path |awk -F '/' '{print $NF}'`
Block_DB_Part=`ls -l $Block_DB_Part_Path |awk -F '/' '{print $NF}'`
Cache_Disk_Slot=`lsscsi|grep disk|awk '{print $1, $NF}'|sed -n 's/\[//g;s/\]//g;s#/dev/##g;s/\ /-/gp'|grep -w "$Cache_Disk"|awk -F '-' '{print $1}'`
Data_Disk_Slot=`lsscsi|grep disk|awk '{print $1, $NF}'|sed -n 's/\[//g;s/\]//g;s#/dev/##g;s/\ /-/gp'|grep -w "$Data_Disk"|awk -F '-' '{print $1}'`

#source "/var/lib/ceph/osd-mapping/osd.$id"
#echo "/var/lib/ceph/osd-mapping/osd.$id"
    if [ -z "$Data_Disk_Path" ]; then
        echo "$Data_Disk_Path is null!"
        exit 1
    else
        echo Data_Disk_Path $Data_Disk_Path
        chown -h ceph:ceph $Data_Disk_Path
    fi
    if [ -z "$Cache_Disk" ]; then
        echo "$Cache_Disk is null!"
        exit 1
    else
        echo $Cache_Disk $Cache_Disk
        chown -h ceph:ceph /dev/$Cache_Disk
    fi
    if [ -z "$Data_Disk" ]; then
        echo "$Data_Disk is null!"
        exit 1
    else
        echo Data_Disk $Data_Disk
        chown -R ceph:ceph /dev/$Data_Disk
    fi
    if [ -z "$Block_DB_Part_Path" ]; then
        echo "$Block_DB_Part_Path is null!"
        exit 1
    else
        echo Block_DB_Part_Path $Block_DB_Part_Path
        chown -h ceph:ceph $Block_DB_Part_Path
    fi
    if [ -z "$Block_DB_Part" ]; then
        echo "$Block_DB_Part is null!"
        exit 1
    else
        echo Block_DB_Part $Block_DB_Part
        chown -R ceph:ceph /dev/$Block_DB_Part
    fi
    if [ -z "$Block_WAL_Part_Path" ]; then
        echo "$Block_WAL_Part_Path is null!"
        exit 1
    else
        echo Block_WAL_Part_Path $Block_WAL_Part_Path
        chown -h ceph:ceph $Block_WAL_Part_Path
    fi
    if [ -z "$Block_WAL_Part" ]; then
        echo "$Block_WAL_Part is null!"
        exit 1
    else
        echo Block_WAL_Part $Block_WAL_Part
        chown -R ceph:ceph /dev/$Block_WAL_Part
    fi


    if [ -z "$Block_BCache_Part_Path" ]; then
        echo "$Block_BCache_Part_Path is null!"
        exit 1
    else
        echo Block_BCache_Part_Path $Block_BCache_Part_Path
        chown -h ceph:ceph $Block_BCache_Part_Path
    fi
    if [ -z "$Block_BCache_Part" ]; then
        echo "$Block_BCache_Part is null!"
        exit 1
    else
        echo Block_BCache_Part $Block_BCache_Part
        chown -R ceph:ceph /dev/$Block_BCache_Part
    fi

    echo "BCache_Device_by_uuid $BCache_Device_by_uuid"
    if [ -h "$BCache_Device_by_uuid" ];then
        chown -h ceph:ceph $BCache_Device_by_uuid
    else
        echo "$BCache_Device_by_uuid not found!"
        exit 1
    fi
    
BCache_Device=`ls -l $BCache_Device_by_uuid|grep bcache|awk -F '/' '{print $NF}'`

    if [ -z "$BCache_Device" ]; then
        echo "$BCache_Device is null!"
        exit 1 
    else
           
        echo BCache_Device $BCache_Device
        if [ -e "/dev/$BCache_Device" ];then
            chown -h ceph:ceph /dev/$BCache_Device
        else
            echo "/dev/$BCache_Device not found!"
            exit 1
        fi
    fi

echo 'write through' > /sys/block/$Data_Disk/queue/write_cache
echo 'write through' > /sys/block/$Data_Disk/device/scsi_disk/$Data_Disk_Slot/cache_type
echo 'write through' > /sys/block/$Cache_Disk/queue/write_cache
echo 'write through' > /sys/block/$Cache_Disk/device/scsi_disk/$Cache_Disk_Slot/cache_type


data="/var/lib/ceph/osd/${cluster:-ceph}-$id"

# assert data directory exists - see http://tracker.ceph.com/issues/17091
if [ ! -d "$data" ]; then
    echo "OSD data directory $data does not exist; bailing out." 1>&2
    exit 1
fi

ceph-bluestore-tool prime-osd-dir --path $data --no-mon-config --dev /dev/$BCache_Device
if [ -h "$data/block" ];then 
    echo "the block symbol exists"
else
    ln -s /dev/$BCache_Device $data/block
fi
if [ -h "$data/block.db" ];then
    echo "the block symbol exists"
else
    ln -s $Block_DB_Part_Path $data/block.db
fi
if [ -h "$data/block.wal" ];then
    echo "the block symbol exists"
else
    ln -s $Block_WAL_Part_Path $data/block.wal
fi
chown -R ceph:ceph $data


journal="$data/journal"

if [ -L "$journal" -a ! -e "$journal" ]; then
    udevadm settle --timeout=5 || :
    if [ -L "$journal" -a ! -e "$journal" ]; then
        echo "ceph-osd(${cluster:-ceph}-$id): journal not present, not starting yet." 1>&2
        exit 0
    fi
fi

# ensure ownership is correct
owner=`stat -c %U $data/.`
if [ $owner != 'ceph' -a $owner != 'root' ]; then
    echo "ceph-osd data dir $data is not owned by 'ceph' or 'root'"
    echo "you must 'chown -R ceph:ceph ...' or similar to fix ownership"
    exit 1
fi


exit 0
