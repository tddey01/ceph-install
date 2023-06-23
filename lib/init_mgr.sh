#!/bin/bash

#Deploy_Path=`cd $(dirname $0); pwd -P`

#source $Deploy_Path/ceph_cluster.env
#source $Deploy_Path/lib/init_ceph_lib.sh



#############################################################################
#start init mgr service
#

#创建mgr服务工作目录
mkdir_mgr_pwd() {
    mkdir -p /var/lib/ceph/mgr/$Cluster_Name-$MGR_NAME && chown -R ceph:ceph /var/lib/ceph
}

#创建允许ceph-mgr服务放行防火墙规则
allow_mgr_firewall() {
    firewall-cmd --zone=public --add-service=ceph-mgr
    firewall-cmd --zone=public --add-service=ceph-mgr --permanent
}

#-----create mgr keyring------#
#创建mgr组件各节点副本的keyring，并赋予其相关组件访问与操作权限
create_mgr_keyring() {
    #注意：ceph auth get-or-create命令是向运行态的mon服务请求创建并输出一个user的keyring，-o可以指定将该user的keyring输出至一个文件，get-or-create命令有个特性就是当指定的用户已存在时，直接输出请求该用户权限的keyring，如果指定用户不存在时，mon创建该用户并赋予该用户命令中携带的权限，最后输出该用户的keyring。
    ceph --cluster $Cluster_Name auth get-or-create mgr.$MGR_NAME  mon 'allow profile mgr' osd 'allow *' mds 'allow *' -o /var/lib/ceph/mgr/$Cluster_Name-$MGR_NAME/keyring && chown -R ceph:ceph /var/lib/ceph
}

#按照自定义集群名称修改mgr的systemd unit，默认集群名为ceph
modify_mgr_systemd_unit() {
    deb_name=`ls -l /var/cache/apt/archives/|egrep ceph-mgr*.deb`
    #MGR_Service_File=`rpm -ql ceph-mgr|grep -w 'ceph-mgr@.service'`
    MGR_Service_File=`dpkg -c $deb_name|grep -w 'ceph-mgr@.service'`
    Service_Path=`dirname $MGR_Service_File`
    Source_Cluster=`sed -n 's/Environment=CLUSTER=//p' $MGR_Service_File`
    if [ "$Source_Cluster"x == "$Cluster_Name"x ];then
        echo "当前ceph cluster name无需修改。"
    else
        cp -a -f $MGR_Service_File $Service_Path/$Cluster_Name-ceph-mgr@.service
        sed -i "s/Environment=CLUSTER=.*/Environment=CLUSTER=$Cluster_Name/g" $Service_Path/$Cluster_Name-ceph-mgr@.service
    fi
}

#启动ceph-mgr服务，并设置服务自启动
start_mgr_service() {
    if [ "$Cluster_Name"x == "ceph"x ];then
        systemctl daemon-reload && systemctl start ceph-mgr@$MGR_NAME && systemctl enable ceph-mgr@$MGR_NAME
    else
        systemctl daemon-reload && systemctl start $Cluster_Name-ceph-mgr@$MGR_NAME && systemctl enable $Cluster_Name-ceph-mgr@$MGR_NAME
    fi
}

#启用mgr dashboard模块，启用后可以使用web查看mgr收集的ceph集群信息
enable_mgr_dashboard() {
    ceph --cluster $Cluster_Name mgr module enable 'dashboard' --force
}

#为mgr dashboard模块生成一个ssl自签证书，用于https访问web
gen_mgr_dashboard_ssl_cert() {
    #检查集群是否开启mgr dashboard https web服务
    ceph --cluster $Cluster_Name mgr services |egrep -w '"dashboard": "https:'.*8443\/\"
    if [ "$?"x != "0"x ];then
        echo "集群尚未开启mgr dashboard https web服务，执行启动操作......"
        ceph --cluster $Cluster_Name dashboard create-self-signed-cert
    else
        echo "集群已开启mgr dashboard https web服务！跳过此操作"
    fi
}

#为mgr dashboard创建管理员用户
create_mgr_dashboard_admin_user(){
    echo $MGR_ADMIN_PASS > /var/lib/ceph/tmp/mgr_admin_pass
    ceph  --cluster $Cluster_Name dashboard ac-user-create $MGR_ADMIN_USER administrator --force-password -i /var/lib/ceph/tmp/mgr_admin_pass
}

enable_mgr_prometheus(){
    ceph --cluster $Cluster_Name mgr module enable prometheus
}


create_mgr() {
    if [ -e "/etc/ceph/$Cluster_Name.conf" ];then
        echo "/etc/ceph/$Cluster_Name.conf文件已存在！"
    else
        get_ceph_conf
    fi
    if [ -e "/etc/ceph/$Cluster_Name.client.admin.keyring" ];then
        echo "/etc/ceph/$Cluster_Name.client.admin.keyring文件已存在！"
    else
        get_client_admin_keyring
    fi

    mkdir_mgr_pwd
    if [ "$OS_Type"x == centosx ];then
        allow_mgr_firewall
    elif [ "$OS_Type"x == opencloudosx ];then
        allow_mgr_firewall
    else
        echo "ubuntu firewall to pre-init-system-all-nodes.sh disable."
    fi
    create_mgr_keyring
    chown_ceph_pwd
    #modify_mgr_systemd_unit
    systemctl_daemon_reload
    start_mgr_service
    sleep 5s
    enable_mgr_dashboard
    sleep 5s
    gen_mgr_dashboard_ssl_cert
    sleep 15s
    create_mgr_dashboard_admin_user
    sleep 5s
    enable_mgr_prometheus

}
#
#init mgr service done
#############################################################################

