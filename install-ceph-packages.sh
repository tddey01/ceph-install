#!/bin/bash
Deploy_Path=`cd $(dirname $0); pwd -P`
source $Deploy_Path/ceph_cluster.env


# for centos
yum_install_ceph_repo() {
    dnf install -y epel-release
    cp -f $Deploy_Path/repos.d/ceph.repo $Deploy_Path/repos.d/ceph.repo.tmp
    sed -i "s/quincy/$ceph_version/g"  $Deploy_Path/repos.d/ceph.repo.tmp
    cp -f $Deploy_Path/repos.d/ceph.repo.tmp /etc/yum.repos.d/
    dnf clean all && dnf makecache
}

yum_install_ceph_packages() {
     dnf install -y lsscsi parted sed grep  chrony ceph ceph-mgr-dashboard ceph-volume rbd-mirror

}

apt_install_ceph_repo() {
    wget -q -O- 'https://mirrors.aliyun.com/ceph/keys/release.asc' | apt-key add -
    apt-add-repository -y "deb https://mirrors.aliyun.com/ceph/debian-$ceph_version/ $OS_Version main" && apt-get update
}

apt_install_ceph_packages() {
    apt-get install -yq apt-file dpkg lsscsi parted sed grep chrony ceph ceph-mgr-dashboard ceph-volume rbd-mirror
}


install_packages(){
    if [ "$OS_Type"x == ubuntux ];then 
        apt_install_ceph_repo
        apt_install_ceph_packages
    elif [ "$OS_Type"x == centosx ];then
        yum_install_ceph_repo
        yum_install_ceph_packages
    elif [ "$OS_Type"x == opencloudosx ];then
        yum_install_ceph_repo
        yum_install_ceph_packages
    else
        echo "The OS_Type $OS_Type is not supported!"
        exit 1
    fi
}
install_packages
