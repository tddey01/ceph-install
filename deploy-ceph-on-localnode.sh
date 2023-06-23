#!/bin/bash

Deploy_Path=`cd $(dirname $0); pwd -P`

source $Deploy_Path/ceph_cluster.env
source $Deploy_Path/lib/init_ceph_lib.sh
source $Deploy_Path/lib/init_chrony.sh
source $Deploy_Path/lib/init_mon.sh
source $Deploy_Path/lib/init_mds.sh
source $Deploy_Path/lib/init_mgr.sh
source $Deploy_Path/lib/init_osd_blustore.sh

deploy_chrony(){
    if [ "$Chrony"x == "yes"x ];then
        deploy_chrony
    fi
}

deploy_mon(){
    create_mon
}

deploy_mds(){
    create_mds
}

deploy_mgr(){
    create_mgr
}

deploy_osd(){
    create_osd
}



deploy_all() {
    echo $mon_nodes|grep -w $HostName
    if [ "$?"x = "0"x ];then
        deploy_mon
    fi

    echo $mds_nodes|grep -w $HostName
    if [ "$?"x = "0"x ];then
        echo "deploy ceph mds "
        deploy_mds
    fi

    echo $mgr_nodes|grep -w $HostName
    if [ "$?"x = "0"x ];then
        echo "deploy ceph mgr"
        deploy_mgr
    fi

    echo $osd_nodes|grep -w $HostName
    if [ "$?"x = "0"x ];then
        echo "deploy ceph osd"
        deploy_osd
    fi
    ceph_crash_achive_all

}

deploy_all
exit 0
