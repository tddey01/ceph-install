#!/bin/bash

#Deploy_Path=`cd $(dirname $0); pwd -P`

#source $Deploy_Path/ceph_cluster.env
#source $Deploy_Path/lib/init_ceph_lib.sh

#############################################################################
#start init mds service
#

#创建mds服务工作目录
mkdir_mds_pwd() {
    mkdir -p /var/lib/ceph/mds/$Cluster_Name-$MDS_NAME && chown -R ceph:ceph /var/lib/ceph
}

#创建允许ceph-mds服务放行防火墙规则
allow_mds_firewall() {
    firewall-cmd --zone=public --add-service=ceph-mds
    firewall-cmd --zone=public --add-service=ceph-mds --permanent
}

#-----create mds keyring------#
create_mds_keyring() {
    ##在本节点中向mon申请创建三个mds节点身份的keyring，并对每个身份的keyring赋予mon服务中仅关于mds服务相关的功能授权，osd服务的所有授权，mds服务的所有授权
    ceph --cluster $Cluster_Name auth get-or-create mds.$MDS_NAME mon 'allow profile mds' osd 'allow rwx' mds 'allow *' -o /var/lib/ceph/mds/$Cluster_Name-$MDS_NAME/keyring && chown -R ceph:ceph /var/lib/ceph

}

#按照自定义集群名称修改mgr的systemd unit，默认集群名为ceph
modify_mds_systemd_unit() {
    deb_name=`ls -l /var/cache/apt/archives/|egrep ceph-mds*.deb`
    #MDS_Service_File=`rpm -ql ceph-mds|grep -w 'ceph-mds@.service'`
    MDS_Service_File=`dpkg -c $deb_name|grep -w 'ceph-mds@.service'`
    Service_Path=`dirname $MDS_Service_File`
    Source_Cluster=`sed -n 's/Environment=CLUSTER=//p' $MDS_Service_File`
    if [ "$Source_Cluster"x == "$Cluster_Name"x ];then
        echo "当前ceph cluster name无需修改。"
    else
        cp -a -f $MDS_Service_File $Service_Path/$Cluster_Name-ceph-mds@.service
        sed -i "s/Environment=CLUSTER=.*/Environment=CLUSTER=$Cluster_Name/g" $Service_Path/$Cluster_Name-ceph-mds@.service
    fi
}


#启动ceph-mgr服务，并设置服务自启动
start_mds_service() {
    if [ "$Cluster_Name"x == "ceph"x ];then
        systemctl daemon-reload && systemctl start ceph-mds@$MDS_NAME && systemctl enable ceph-mds@$MDS_NAME
    else
	systemctl daemon-reload && systemctl start $Cluster_Name-ceph-mds@$MDS_NAME && systemctl enable $Cluster_Name-ceph-mds@$MDS_NAME
    fi
}


create_mds() {
    if [ -e "/etc/ceph/$Cluster_Name.conf" ];then
        echo "$Cluster_Name.conf已存在！"
    else
        get_ceph_conf
    fi
        if [ -e "/etc/ceph/$Cluster_Name.client.admin.keyring" ];then
        echo "/etc/ceph/$Cluster_Name.client.admin.keyring文件已存在！"
    else
        get_client_admin_keyring
    fi
    mkdir_mds_pwd
    if [ "$OS_Type"x == centosx ];then
        allow_mds_firewall
    elif [ "$OS_Type"x == opencloudosx ];then
        allow_mds_firewall
    else
        echo "ubuntu firewall to pre-init-system-all-nodes.sh disable."
    fi
    create_mds_keyring
    chown_ceph_pwd
    #modify_mds_systemd_unit
    systemctl_daemon_reload
    start_mds_service
}
#
#init mds service done
############################################################################

