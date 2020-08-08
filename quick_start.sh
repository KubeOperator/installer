#!/usr/bin/env bash
#Install Latest Stable KubeOperator Release

#  定义离线文件下载地址
export CURRENT_DIR=$(cd "$(dirname "$0")";pwd)
export KO_VERSION=$(curl -s https://github.com/wanghe-fit2cloud/KubeOperator/releases/latest/download 2>&1 |grep -Eo "v([0-9]{1,}\.)+[0-9]{1,}")
export ANSIBLE_VERSION=$(curl -s https://github.com/KubeOperator/ansible/releases/latest/download 2>&1 |grep -Eo "v([0-9]{1,}\.)+[0-9]{1,}")

nexus_download_url="https://kubeoperator.fit2cloud.com/nexus/nexus-${KO_VERSION}.tar.gz"
ansible_download_url="https://github.com/KubeOperator/ansible/archive/${KO_VERSION}.tar.gz"
kubeoperator_download_url="https://github.com/wanghe-fit2cloud/KubeOperator/releases/latest/download/kubeoperator-installer-${KO_VERSION}.tar.gz"

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
function download() {
  mkdir -p ${CURRENT_DIR}/kubeoperator-release-${KO_VERSION}
  wget --no-check-certificate $nexus_download_url -P ${CURRENT_DIR}/kubeoperator-release-${KO_VERSION}
  wget --no-check-certificate $ansible_download_url -P ${CURRENT_DIR}/kubeoperator-release-${KO_VERSION}
  wget --no-check-certificate $kubeoperator_download_url -P ${CURRENT_DIR}/kubeoperator-release-${KO_VERSION}

  if [ -f ${CURRENT_DIR}/kubeoperator-release-${KO_VERSION}/kubeoperator-installer-${KO_VERSION}.tar.gz ];then
  # 执行在线安装
    echo "开始解压离线包..."
    tar zxvf ${CURRENT_DIR}/kubeoperator-release-${KO_VERSION}/kubeoperator-installer-${KO_VERSION}.tar.gz -C ${CURRENT_DIR}/kubeoperator-release-${KO_VERSION}> /dev/null 2>&1
  fi
}

if [ ! -d ${CURRENT_DIR}/kubeoperator-release-${KO_VERSION} ];then
  download
elif [ ! -e ${CURRENT_DIR}/kubeoperator-release-${KO_VERSION}/nexus-${KO_VERSION}.tar.gz ]; then
  wget --no-check-certificate $nexus_download_url -P ${CURRENT_DIR}/kubeoperator-release-${KO_VERSION}
elif [ ! -e ${CURRENT_DIR}/kubeoperator-release-${KO_VERSION}/${KO_VERSION}.tar.gz  ]; then
  wget --no-check-certificate $ansible_download_url -P ${CURRENT_DIR}/kubeoperator-release-${KO_VERSION}
else
  echo "离线包已经下载完成"
fi

cd ${CURRENT_DIR}/kubeoperator-release-${KO_VERSION}/installer/
/bin/bash install.sh