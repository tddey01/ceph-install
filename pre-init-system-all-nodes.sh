#!/bin/bash

Deploy_Path=`cd $(dirname $0); pwd -P`
source $Deploy_Path/ceph_cluster.env


yum_install_sshpass(){
    dnf install -y sshpass util-linux lsscsi parted sed grep egrep
    for i in $mgmt_ips;do
    {
        sshpass -p $ROOT_PASSWD ssh -p $ssh_port -t -o stricthostkeychecking=no -l root $i "dnf install sshpass lsscsi parted sed grep egrep sysstat gawk -y"
    }&
    wait
    done
}

apt_install_sshpass() {
    export DEBIAN_FRONTEND=noninteractive
    apt-get remove unattended-upgrades -yq
    apt-get update -yq
    apt-get upgrade -yq
    apt-get autoremove -yq
    apt-get install -yq sshpass lsscsi parted sed grep gawk
    apt-get autoremove -yq
    for i in $mgmt_ips;do
    {
        sshpass -p $ROOT_PASSWD ssh -p $ssh_port -t -o stricthostkeychecking=no -l root $i "export DEBIAN_FRONTEND=noninteractive && apt-get update -yq && apt-get upgrade -yq && apt-get autoremove -yq && apt-get install sshpass lsscsi parted sed grep  -yq && apt-get autoremove -yq"
    }&
    wait
    done
}

install_sshpass() {
    if [ "$OS_Type"x == ubuntux ];then
        apt_install_sshpass
    elif [ "$OS_Type"x == centosx ];then
        yum_install_sshpass
    elif [ "$OS_Type"x == opencloudosx ];then
        yum_install_sshpass
    else
        echo "The OS_Type $OS_Type is not supported!"
        exit 1
    fi

}

install_repos() {
    for i in $mgmt_ips;do
        echo $i
        ssh -p $ssh_port -t -o stricthostkeychecking=no -l root $i "bash $Deploy_Path/install-repos.sh"
    done
}


optim_ssh(){
    sed -i s"/^.*ConnectTimeout.*$/    ConnectTimeout 60/g" /etc/ssh/ssh_config
}

ubuntu_disable_firewall(){
    ufw disable
}

clean_all_ssh_key() {
    rm -f ~/.ssh/*
    echo $mgmt_ips
    for i in $mgmt_ips;do
        echo $i
        sshpass -p $ROOT_PASSWD ssh -p $ssh_port  -t -o stricthostkeychecking=no -l root $i 'rm -f /root/.ssh/*'
    done
}

gen_ssh_key() {
    echo $mgmt_ips
    for i in $mgmt_ips;do
        echo $i
        sshpass -p $ROOT_PASSWD ssh -p $ssh_port -t -o stricthostkeychecking=no -l root $i 'ssh-keygen -t rsa -P "" -f /root/.ssh/id_rsa && echo ssh-keygen > /tmp/test'
    done
}

auth_ssh_key() {

    fqdn_ips=$(cat $Deploy_Path/conf/hosts|egrep -v "^$|^#"|grep $Cluster_Domain)
    ips=$(echo $fqdn_ips|awk '{print $1}')
    for i in $fqdn_ips;do 
        fqdn_ip=$i
	fqdn=$(echo $fqdn_ip|awk '{$1=""; sub(/^ +/, ""); print $0}')
        for a in $fqdn_ip;do
            sshpass -p $ROOT_PASSWD scp -P $ssh_port $a:/root/.ssh/id_rsa.pub /tmp/
        
            cat /tmp/id_rsa.pub |awk -F '@' '{print $1}'|sed -n 's/$/\@'"$a"'/gp'>> ~/.ssh/authorized_keys 
            chmod 600 ~/.ssh/authorized_keys

            sshpass -p $ROOT_PASSWD ssh -p $ssh_port -l root -o stricthostkeychecking=no $a echo "`hostname` $a Authentication Succeeded!"
        done
    done
    for i in $mgmt_ips;do
        sshpass -p $ROOT_PASSWD scp -P $ssh_port ~/.ssh/authorized_keys  $i:~/.ssh/
        sshpass -p $ROOT_PASSWD scp -P $ssh_port ~/.ssh/known_hosts  $i:~/.ssh/
        sshpass -p $ROOT_PASSWD ssh -p $ssh_port  -l root -o stricthostkeychecking=no $i 'chmod 600 ~/.ssh/authorized_keys'
        sshpass -p $ROOT_PASSWD ssh -p $ssh_port  -l root -o stricthostkeychecking=no $i 'chmod 644 ~/.ssh/known_hosts'
    done
}


echo "Deploy_Path $Deploy_Path"
send_files() {
    echo "Deploy_Path $Deploy_Path"
    host_ip=$(cat $Deploy_Path/conf/hosts |egrep -v "^#|^$"|grep -w `hostname` |grep $Cluster_Domain |awk '{print $1}')
    echo $host_ip
    cp -f $Deploy_Path/conf/hosts /etc/hosts    
    echo $mgmt_ips
    for i in $mgmt_ips;do
        sshpass -p $ROOT_PASSWD ssh -p $ssh_port -t -l root $i "if [ -d $Deploy_Path ]; then echo $Deploy_Path directory exists; else mkdir -p  $Deploy_Path ;fi"
        sshpass -p $ROOT_PASSWD scp -P $ssh_port -r $Deploy_Path/* $i:$Deploy_Path/ && echo "Scripts transfer completed."
        sshpass -p $ROOT_PASSWD scp -P $ssh_port $Deploy_Path/conf/hosts $i:/etc/hosts && echo "hosts file transfer completed."
    done
}

set_hostname() {
    for i in $Hostnames;do 
    {
        sshpass -p $ROOT_PASSWD ssh -p $ssh_port -t -o stricthostkeychecking=no -l root $i "hostnamectl set-hostname $i && echo hostname >> /tmp/test"
    }&
    wait
    done
}

deploy_chrony(){
    for i in $mgmt_ips;do
    {
        sshpass -p $ROOT_PASSWD ssh -p $ssh_port -t -o stricthostkeychecking=no -l root $i "bash $Deploy_Path/init_chrony.sh"
    }&
    wait
    done
}

install_ceph_packages() {
    for i in $mgmt_ips;do 
    {
        ssh -p $ssh_port -t -o stricthostkeychecking=no -l root $i "bash $Deploy_Path/lib/install_ceph_packages.sh"
    }&
    wait
    done
}

node_reboot() {
    for i in $mgmt_ips;do
    {
        ssh -p $ssh_port -t -o stricthostkeychecking=no -l root $i "reboot"
    }&
    wait
    done
}

set_timezone(){
    for i in $mgmt_ips;do
    {
        ssh -p $ssh_port -t -o stricthostkeychecking=no -l root $i "timedatectl set-timezone Asia/Shanghai"
    }&
    wait
    done

}

init_system() {
    #install_sshpass
    #optim_ssh
    #clean_all_ssh_key
    #set_hostname
    send_files
    #gen_ssh_key
    #auth_ssh_key
    set_timezone
    #ubuntu_disable_firewall
    #install_repos
    #node_reboot
}

init_system
