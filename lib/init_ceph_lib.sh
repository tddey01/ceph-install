#!/bin/bash

#从第一个mon节点scp ceph.conf文件到当前节点
get_ceph_conf(){
    for ((i=0; 1<5; i++));do
        scp -P $ssh_port  $Deploy_Node:/etc/ceph/$Cluster_Name.conf /etc/ceph/$Cluster_Name.conf && chown -R ceph:ceph /etc/ceph
        if [ "$?"x == "0"x ];then
            echo "第一个mon节点配置文件已生成！"
            break
        else
	    echo "第一个mon节点配置文件未生成！等待10s后自动重试......"
	    sleep 10s
        fi
    done
}

#从已存在的mon服务运行的节点scp client.admin.keyring文件到当前节点，并将属主和数组改为ceph用户ceph组（在扩容的mon节点执行）
get_client_admin_keyring() {
    scp -P $ssh_port $Deploy_Node:/etc/ceph/$Cluster_Name.client.admin.keyring /etc/ceph/$Cluster_Name.client.admin.keyring && chown -R ceph:ceph /etc/ceph
}

#从已存在的mon服务运行的节点scp client.bootstrap-osd keyring文件到当前节点，并将属主和数组改为ceph用户ceph组（在扩容的mon节点执行）
get_bootstrap_osd_keyring() {
    #ceph --cluster $Cluster_Name auth get client.bootstrap-osd -o /var/lib/ceph/bootstrap-osd/$Cluster_Name.keyring && chown -R ceph:ceph /var/lib/ceph  #弃用，当ceph-mon master节点没起来之前改命令无法获取keyring，徒增等待时间
    scp -P $ssh_port $Deploy_Node:/var/lib/ceph/bootstrap-osd/$Cluster_Name.keyring /var/lib/ceph/bootstrap-osd/$Cluster_Name.keyring && chown -R ceph:ceph /var/lib/ceph
}

systemctl_daemon_reload(){
    systemctl daemon-reload
}

ceph_crash_achive_all(){
    if ! ceph crash archive-all;then
        echo "ceph crash archive-all is faild!"
    fi
}
