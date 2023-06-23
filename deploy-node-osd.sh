#!/bin/bash
Deploy_Path=`cd $(dirname $0); pwd -P`

source $Deploy_Path/ceph_cluster.env
source $Deploy_Path/lib/init_ceph_lib.sh
source $Deploy_Path/lib/init_chrony.sh
source $Deploy_Path/lib/init_osd_blustore.sh

deploy_chrony(){
    if [ "$Chrony"x == "yes"x ];then
        deploy_chrony
    fi
}

deploy_osd(){
    bash $Deploy_Path/lib/install_ceph_packages.sh
    create_osd
}

echo $osd_nodes|grep -w $HostName
if [ "$?"x = "0"x ];then
    echo "deploy ceph osd"
    deploy_osd >> $Deploy_Path/logs/ceph-deploy-`date +'%Y-%m-%d-%H-%M-%S'`.log 2>&1 
fi
exit 0
