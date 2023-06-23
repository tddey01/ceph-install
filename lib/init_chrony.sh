#!/bin/bash
#Chrony_Sources='ntp.aliyun.com'
#Deploy_Path=`cd $(dirname $0); pwd -P`

#source $Deploy_Path/ceph_cluster.env


yum_install_chrony(){
    dnf install -y chrony
}
apt_install_chrony() {
    apt-get install -y chrony
}

deploy_NTP_source(){
    sed -i '/#allow .*/a allow '"$Public_Net"'' /etc/chrony.conf
}

modify_client_source(){
    sed -i '/^pool .*/ s/^/#/g' /etc/chrony.conf
    sed -i '/^server .*/ s/^/#/g' /etc/chrony.conf
    for i in $Chrony_Sources;do
        sed -i '/^#pool .*/a server '"$i"' iburst' /etc/chrony.conf
    done
}

enable_hwtimestamp(){
    sed -i 's/^#hwtimestamp .*/hwtimestamp */g' /etc/chrony.conf
}

enable_chrony(){
    systemctl start chrony && systemctl enable chrony && chronyc sources
}

#安装步骤放在pre-init-system.sh
#install_chrony
deploy_chrony(){
    modify_client_source
    enable_hwtimestamp
    systemctl_daemon_reload
    enable_chrony
}
#exit 0
