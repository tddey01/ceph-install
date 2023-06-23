#!/bin/bash
Deploy_Path=`cd $(dirname $0); pwd -P`
source $Deploy_Path/ceph_cluster.env


yum_install_repos(){
    mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
    wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-vault-8.5.2111.repo
    yum clean all && yum makecache

}

apt_install_repos(){
    #deb https://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse
    #deb-src https://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse

    #deb https://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse
    #deb-src https://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse

    #deb https://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse
    #deb-src https://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse

    # deb https://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse
    # deb-src https://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse

    #deb https://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse
    #deb-src https://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse

    sed -i 's/https:\/\/mirrors.aliyun.com/http:\/\/mirrors.aliyun.com/g' /etc/apt/sources.list
    apt-get update -yq
}


install_repos() {
    if [ "$OS_Type"x == ubuntux ];then
        apt_install_repos
    elif [ "$OS_Type"x == centosx ];then
        yum_install_repos
    elif [ "$OS_Type"x == opencloudosx ];then
        echo 'opencloudos'
    else
        echo "The OS_Type $OS_Type is not supported!"
        exit 1
    fi

}

install_repos
