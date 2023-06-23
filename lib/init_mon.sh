#!/bin/bash

#Deploy_Path=`cd $(dirname $0); pwd -P`

#source $Deploy_Path/ceph_cluster.env
#source $Deploy_Path/lib/init_ceph_lib.sh

######################################################################
#start init mon service
#

#仅在第一个mon节点执行
ceph_conf() {
    #在所有ceph节点上设置/etc/ceph目录及其子文件属主为ceph用户ceph组
    cp -f $Deploy_Path/conf/ceph.conf /etc/ceph/$Cluster_Name.conf  && chown -R ceph:ceph /etc/ceph
}

#create ceph.conf
modify_ceph_conf() {
    #修改文件中mon_host列表
    MON_HOSTS=$(echo $MON_Nodes|sed 's/[ ]/,/g')
    sed -i 's/^mon_host = .*/mon_host = '"$MON_HOSTS"'/g' /etc/ceph/$Cluster_Name.conf
    echo /etc/ceph/$Cluster_Name.conf
    #修改配置文件中cluster_network的值
    sed -i 's#^cluster_network.*#cluster_network = '"$Cluster_CIDR"'#g' /etc/ceph/$Cluster_Name.conf
    echo /etc/ceph/$Cluster_Name.conf
    #修改配置文件中public_network的值
    sed -i 's#^public_network.*#public_network = '"$Public_CIDR"'#g' /etc/ceph/$Cluster_Name.conf
    #生成ceph集群fsid,并在ceph.conf配置文件中修改集群fsid为当前生成的fsid
    FSID=`uuidgen`
    sed -i 's/^fsid.*/fsid = '"$FSID"'/g' /etc/ceph/$Cluster_Name.conf
    echo /etc/ceph/$Cluster_Name.conf
}

#(函数迁移至init_ceph_lib.sh公共库中)
#从第一个mon节点scp ceph.conf文件到当前节点
#get_ceph_conf(){
#scp $Deploy_Node:/etc/ceph/$Cluster_Name.conf /etc/ceph/$Cluster_Name.conf && chown -R ceph:ceph /etc/ceph
#}

#检查并创建ceph工作目录
mkdir_mon_pwd(){
    #在节点上设置/var/lib/ceph目录及其子文件属主为ceph用户ceph组
    mkdir -p /var/lib/ceph/mon/$Cluster_Name-$MON_NAME && chown -R ceph:ceph /var/lib/ceph
}

#将所有ceph工作目录都设置为ceph用户ceph组
chown_ceph_pwd() {
    chown -R ceph:ceph /var/lib/ceph
    chown -R ceph:ceph /etc/ceph
}

#仅在第一个mon节点执行
#创建keyring，注意ceph-authtool --create-keyring命令用于离线创建keyring，mon服务初始化之前必须使用该命令创建离线mon.用户的keyring，用于后面通过ceph-mon mkfs命令将mon.用户离线keyring文件导入mon的rocksdb数据库中，如果mon服务初始化完成，再创建新的keyring一般使用ceph auth get-or-create命令或者通过ceph-authtool --create-keyring创建离线keyring后再使用ceph auth add 命令导入mon数据库。
create_mon_keyring() {
    #-----create mon. keyring------#
    #创建一个用户名为 mon. 的mon初始化(bootstrap)keyring，并赋予其mon的所有操作权限，相当于client.bootstrap-osd的keyring，用于创建mon节点时以此用户身份为新的mon节点创建keyring
    ceph-authtool --create-keyring /var/lib/ceph/tmp/$Cluster_Name.mon.keyring --gen-key -n mon. --cap mon 'allow *'
}

create_client_admin_keyring(){
    #-----create client.admin keyring------#
    #创建一个用户名为 client.admin 的keyring，此为client类型admin用户，用于用户管理整个ceph存储集群使用，赋予该用户ceph平台所有组件的client端的所有操作权限，使用--cap指定ceph组件名称，'allow *'代表允许所有操作
    ceph-authtool --create-keyring /etc/ceph/$Cluster_Name.client.admin.keyring --gen-key -n client.admin  --cap mon 'allow *' --cap osd 'allow *' --cap mds 'allow *' --cap mgr 'allow *'
}

create_osd_bootstrap_keyring(){
    #-----create osd bootstrap keyring------#
    #创建一个用户名为 client.bootstrap-osd 的keyring，此用户为osd的初始化用户，用于创建osd时以此用户身份为新的osd进程创建keyring，此身份拥有mon服务关于osd boostrap相关操作的权限
    ceph-authtool --create-keyring /var/lib/ceph/bootstrap-osd/$Cluster_Name.keyring --gen-key -n client.bootstrap-osd --cap  mon 'profile bootstrap-osd'
}

import_to_mon_keyring(){
    #-----合并client.admin和bootstrap-osd两个用户的权限到ceph.mon.keyring--------#
    #将ceph.client.admin.keyring和bootstrap-osd用户的ceph.keyring都导入ceph.mon.keyring中，使ceph.mon.keyring拥有bootstrap-osd与client.admin等用户的密钥
    ceph-authtool /var/lib/ceph/tmp/$Cluster_Name.mon.keyring --import-keyring /etc/ceph/$Cluster_Name.client.admin.keyring
    ceph-authtool /var/lib/ceph/tmp/$Cluster_Name.mon.keyring --import-keyring /var/lib/ceph/bootstrap-osd/$Cluster_Name.keyring
}


#使用第一个mon的名称、ip地址、端口等信息创建一个monmap文件（仅在第一个mon节点执行）
create_monmap() {
    #创建集群monmap
    monmaptool --create --add $MON_NAME $MON_IP --fsid $FSID /var/lib/ceph/tmp/$Cluster_Name-monmap
}

#从已存在的mon服务中获取现行monmap并输出到文件（在扩容的mon节点执行）
get_monmap() {
    ceph --cluster $Cluster_Name mon getmap -o /var/lib/ceph/tmp/$Cluster_Name-monmap
}

#使用当前扩容mon节点的mon名称、ip地址、端口等信息向已有的monmap文件中添加mon信息（在扩容的mon节点执行）
add_monmap() {
    monmaptool --add $MON_NAME $MON_IP  /var/lib/ceph/tmp/$Cluster_Name-monmap
}

#(函数迁移至init_ceph_lib.sh公共库中)
#从已存在的mon服务运行的节点scp client.admin.keyring文件到当前节点，并将属主和数组改为ceph用户ceph组（在扩容的mon节点执行）
#get_client_admin_keyring() {
#scp $Deploy_Node:/etc/ceph/$Cluster_Name.client.admin.keyring /etc/ceph/$Cluster_Name.client.admin.keyring && chown -R ceph:ceph /etc/ceph
#}

#从已存在的mon服务运行的节点scp mon.keyring文件到当前节点，并将属主和数组改为ceph用户ceph组（在扩容的mon节点执行）
get_mon_keyring() {
    scp -P $ssh_port $Deploy_Node:/var/lib/ceph/tmp/$Cluster_Name.mon.keyring /var/lib/ceph/tmp/$Cluster_Name.mon.keyring && chown -R ceph:ceph /var/lib/ceph
    #ceph --cluster $Cluster_Name auth get mon. -o /var/lib/ceph/tmp/$Cluster_Name.mon.keyring && chown -R ceph:ceph /var/lib/ceph
}

#(函数迁移至init_ceph_lib.sh公共库中)
#从已存在的mon服务运行的节点scp client.bootstrap-osd keyring文件到当前节点，并将属主和数组改为ceph用户ceph组（在扩容的mon节点执行）
#get_bootstrap_osd_keyring() {
    #ceph --cluster $Cluster_Name auth get client.bootstrap-osd -o /var/lib/ceph/bootstrap-osd/$Cluster_Name.keyring && chown -R ceph:ceph /var/lib/ceph
#scp $Deploy_Node:/var/lib/ceph/bootstrap-osd/$Cluster_Name.keyring /var/lib/ceph/bootstrap-osd/$Cluster_Name.keyring && chown -R ceph:ceph /var/lib/ceph
#}

#新版本不需要额外执行ceph mon add命令，该函数没有被使用
add_mon() {
    ceph --cluster $Cluster_Name mon add $MON_NAME $MON_IP
}

#始化mon数据库
init_mon() {
    #此步骤为真正初始化mon服务的步骤,使用 ceph-mon --mkfs 命令初始化一个mon节点，由下面命令行的参数可知 -i后面是要创建的mon节点名称，--monmap表示将指定的monmap导入到新创建的mon节点的数据库中，--keyring表示将指定的keyring导入到新创建的mon节点的数据库中
    sudo -u ceph ceph-mon --cluster $Cluster_Name --mkfs -i $MON_NAME --monmap /var/lib/ceph/tmp/$Cluster_Name-monmap --keyring /var/lib/ceph/tmp/$Cluster_Name.mon.keyring && sleep 5s || exit 1
}

#修改mon的systemd unit文件中的集群名称，适用于自定义ceph集群名称的部署
modify_mon_systemd_unit() {
    deb_name=`ls -l /var/cache/apt/archives/|egrep ceph-mon*.deb`
    #获取mon service unit文件绝对路径
    #MON_Service_File=`rpm -ql ceph-mon|grep -w 'ceph-mon@.service'`
    MON_Service_File=`dpkg -c $deb_name|grep -w 'ceph-mon@.service'`
    #获取mon service unit文件所在目录
    Service_Path=`dirname $MON_Service_File`
    #获取mon service unit文件中默认配置的集群名称
    Source_Cluster=`sed -n 's/Environment=CLUSTER=//p' $MON_Service_File`
    #按当前部署ceph的集群名称克隆并修改mon的systemd unit文件，默认为ceph时不做修改
    if [ "$Source_Cluster"x == "$Cluster_Name"x ];then
        echo "当前ceph cluster name无需修改。"
    else
        cp -a -f $MON_Service_File $Service_Path/$Cluster_Name-ceph-mon@.service
        sed -i "s/Environment=CLUSTER=.*/Environment=CLUSTER=$Cluster_Name/g" $Service_Path/$Cluster_Name-ceph-mon@.service
    fi
}

#创建放行mon服务的防火墙规则
allow_mon_firewall() {
    firewall-cmd --zone=public --add-service=ceph-mon
    firewall-cmd --zone=public --add-service=ceph-mon --permanent
}

#启动mon服务并将mon服务设置为自启动服务
enable_mon_service() {
    if [ "$Cluster_Name"x == "ceph"x ];then
        systemctl daemon-reload && systemctl start ceph-mon@$MON_NAME && systemctl enable ceph-mon@$MON_NAME
    else
        systemctl daemon-reload && systemctl start $Cluster_Name-ceph-mon@$MON_NAME && systemctl enable $Cluster_Name-ceph-mon@$MON_NAME
    fi
}

#为mon通信启用msg2协议
enable_mon_msgr2(){
    ceph --cluster $Cluster_Name mon enable-msgr2
}

#禁用允许不安全的mon global_id reclaim通信
disable_auth_allow_insecure_global_id_reclaim(){
    ceph --cluster $Cluster_Name config set mon auth_allow_insecure_global_id_reclaim false
}

check_ceph_status() {
    for (( i=1;i<=5;1++));do
        if ssh -p $ssh_port -t -o stricthostkeychecking=no -l root $Deploy_Node "ss -tnlp"|grep -w 'ceph-mon'|grep -w '6789';then
            echo "ceph-mon master process is running!"
        else
            sleep 10
        fi

        if ceph -s;then
            echo "ceph cluster可以正常连接！"
            break
        elif [ $i < 5 ];then
            echo "ceph cluster无法正常连接！"
            sleep 10
        else
            echo "ceph cluster无法正常连接！"
            exit 1
        fi
    done

}

create_frist_mon() {
    mkdir_mon_pwd
    ceph_conf
    modify_ceph_conf
    create_mon_keyring
    create_client_admin_keyring
    create_osd_bootstrap_keyring
    import_to_mon_keyring
    create_monmap
    chown_ceph_pwd
    init_mon
    if [ "$OS_Type"x == centosx ];then
        allow_mon_firewall
    elif [ "$OS_Type"x == opencloudosx ];then
        allow_mon_firewall
    else
        echo "ubuntu firewall to pre-init-system-all-nodes.sh disable."
    fi
    #modify_mon_systemd_unit
    systemctl_daemon_reload
    enable_mon_service
    enable_mon_msgr2
    disable_auth_allow_insecure_global_id_reclaim
    check_ceph_status
}

external_mon() {
    mkdir_mon_pwd
    get_ceph_conf
    get_client_admin_keyring
    get_mon_keyring
    get_bootstrap_osd_keyring
    check_ceph_status
    get_monmap
    add_monmap
    chown_ceph_pwd
    init_mon
    if [ "$OS_Type"x == centosx ];then
        allow_mds_firewall
    elif [ "$OS_Type"x == opencloudosx ];then
        allow_mds_firewall
    else
        echo "ubuntu firewall to pre-init-system-all-nodes.sh disable."
    fi
    #modify_mon_systemd_unit
    enable_mon_service
    enable_mon_msgr2
    sleep 2s
    ceph -s

}

create_mon() {

    #判断当前节点是否为第一个mon节点，如果是则执行mon首节点初始化函数，否则执行mon扩容节点函数
    #echo $Node_FQDN|grep -w $Deploy_Node
    if [ "$Node_FQDN"x == "$Deploy_Node"x ];then
        create_frist_mon
    else
	    #当前节点非mon首节点时，判断当前节点是否能够连接现有运行态mon服务，如果ceph -s可以正常返回，则说明当前节点可以正常连接现有mon服务，可以执行mon扩容函数，如果ceph -s无法正常返回，则说明现有mon服务无法连接，需要检查现有mon服务是否运行，或者检查网络是否可达。

        external_mon
    fi
}

#
#init mon service done
#############################################################################

