#!/bin/bash
Deploy_Path=`cd $(dirname $0); pwd -P`
source $Deploy_Path/lib/init_osd_blustore.sh

OSD_ID=$1
source /var/lib/ceph/osd-mappings/osd.$OSD_ID


make_bluestore_osd_for_replace(){

    OSD_Key=`ceph-authtool --gen-print-key`
    OSD_UUID=`uuidgen`

    shell_make_exclusive_bluestore_osd_step

}

replace_osd(){
    make_bluestore_osd_for_replace
}

replace_osd
