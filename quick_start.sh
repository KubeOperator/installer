#!/usr/bin/env bash
#Install Latest Stable KubeOperator Release

#  定义离线文件下载地址
export CURRENT_DIR=$(cd "$(dirname "$0")";pwd)
export KO_VERSION=$(curl -s https://github.com/KubeOperator/KubeOperator/releases/latest/download 2>&1 |grep -Eo "v([0-9]{1,}\.)+[0-9]{1,}")
export ANSIBLE_VERSION=$(curl -s https://github.com/KubeOperator/ansible/releases/latest/download 2>&1 |grep -Eo "v([0-9]{1,}\.)+[0-9]{1,}")

nexus_download_url="https://kubeoperator.fit2cloud.com/nexus/nexus-${KO_VERSION}.tar.gz"
ansible_download_url="https://github.com/KubeOperator/KubeOperator/releases/latest/download/ansible-${KO_VERSION}.tar.gz"
kubeoperator_download_url="https://github.com/KubeOperator/KubeOperator/releases/latest/download/installer-${KO_VERSION}.tar.gz"

set -e
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

# 判断文件是否存在
if [ ! -d ${CURRENT_DIR}/kubeoperator-release-${KO_VERSION} ];then
  mkdir -p ${CURRENT_DIR}/kubeoperator-release-${KO_VERSION}
else
  rm -rf ${CURRENT_DIR}/kubeoperator-release-${KO_VERSION}/*
fi

# 下载离线包
wget --no-check-certificate $nexus_download_url -P ${CURRENT_DIR}/kubeoperator-release-${KO_VERSION}
wget --no-check-certificate $ansible_download_url -P ${CURRENT_DIR}/kubeoperator-release-${KO_VERSION}
wget --no-check-certificate $kubeoperator_download_url -P ${CURRENT_DIR}/kubeoperator-release-${KO_VERSION}

# 解压离线包
if [ -f ${CURRENT_DIR}/kubeoperator-release-${KO_VERSION}/installer-${KO_VERSION}.tar.gz ];then
  tar zxf ${CURRENT_DIR}/kubeoperator-release-${KO_VERSION}/installer-${KO_VERSION}.tar.gz -C ${CURRENT_DIR}/kubeoperator-release-${KO_VERSION}
fi

if [ -d ${CURRENT_DIR}/kubeoperator-release-${KO_VERSION}/installer ];then
  cd ${CURRENT_DIR}/kubeoperator-release-${KO_VERSION}/installer/
  /bin/bash install.sh
else
  echo "安装失败: ${CURRENT_DIR}/kubeoperator-release-${KO_VERSION}/installer 不存在"
fi
