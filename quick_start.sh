#!/usr/bin/env bash
#Install Latest Stable KubeOperator Release

#  定义离线文件下载地址
export CURRENT_DIR=$(cd "$(dirname "$0")";pwd)
export KO_VERSION=$(curl -s https://github.com/kubeoperator/kubeoperator/releases/latest/download 2>&1 |grep -Eo "v([0-9]{1,}\.)+[0-9]{1,}")
export ANSIBLE_VERSION=$(curl -s https://github.com/KubeOperator/ansible/releases/latest/download 2>&1 |grep -Eo "v([0-9]{1,}\.)+[0-9]{1,}")

nexus_download_url="http://172.16.10.63/ko-3.0/data/nexus/nexus-data.origin.tar.gz"
ansible_download_url="http://172.16.10.63/ko-3.0/data/ansible/ansible.tar.gz"
kubeoperator_download_url="http://172.16.10.63/ko-3.0/data/install-dev/kubeoperator_installer.tar.gz"
#ansible_download_url="https://github.com/KubeOperator/ansible/releases/latest/download/"
#kubeoperator_download_url="https://github.com/KubeOperator/KubeOperator/releases/latest/download/"


# 判断 wget 命令是否安装
if which wget;then
  echo "开始下载离线包"
else
  echo "wget 未安装，即将安装 wget"
  yum install wget -y
  if [ $? = 0 ];then
    echo "wget 安装成功"
  else
    echo "wget 安装失败，请手动安装后再次执行脚本"
  fi
fi

# 下载离线包
wget --no-check-certificate $nexus_download_url
wget --no-check-certificate $ansible_download_url
wget --no-check-certificate $kubeoperator_download_url

if [ -f $CURRENT_DIR/kubeoperator_installer.tar.gz ];then
# 执行在线安装
  echo "开始解压离线包..."
  tar zxvf $CURRENT_DIR/kubeoperator_installer.tar.gz -C $CURRENT_DIR > /dev/null 2>&1
fi
cd $CURRENT_DIR/installer/
/bin/bash install.sh