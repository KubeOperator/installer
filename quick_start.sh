#Install Latest Stable KubeOperator Release

#  定义离线文件下载地址
nexus_download_url="http://172.16.10.63/ko-3.0/data/nexus/nexus-data.origin.tar.gz"
ansible_download_url="http://172.16.10.63/ko-3.0/data/ansible/ansible.tar.gz"
kubeoperator_download_url="http://172.16.10.63/ko-3.0/data/install/kubeoperator_installer.tar.gz"

# 判断 wget 命令是否安装
if which wget;then
  echo "wget 已经安装"
  else
  yum install wget -y
fi

wget --no-check-certificate $nexus_download_url  2&> /dev/null
wget --no-check-certificate $ansible_download_url  2&> /dev/null
wget --no-check-certificate $kubeoperator_download_url  2&> /dev/null

# 解压离线文件
tar zxvf kubeoperator_installer.tar.gz -C /opt/
if [ $? = 0 ];then
  tar zxvf nexus-data.origin.tar.gz -C /opt/installer/kubeoperator/data/
  tar zxvf ansible.tar.gz -C /opt/installer/kubeoperator/data/kobe/project/
  mv /opt/installer/kubeoperator/data/kobe/project/ansible /opt/installer/kubeoperator/data/kobe/project/ko
fi

cd /opt/installer/
/bin/bash install.sh
