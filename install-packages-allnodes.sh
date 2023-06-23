#!/bin/bash
Deploy_Path=`cd $(dirname $0); pwd -P`
source $Deploy_Path/ceph_cluster.env


install_ceph_packages() {
    for i in $Ceph_Hostnames;do
    {
        ssh -p $ssh_port -t -o stricthostkeychecking=no -l root $i "bash $Deploy_Path/install-ceph-packages.sh"
    }&
    wait
    done
}
install_ceph_packages
