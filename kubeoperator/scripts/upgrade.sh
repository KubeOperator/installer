#!/usr/bin/env bash

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "${PROJECT_DIR}/const.sh"
target=$1

function online_upgrade() {
    export LATEST_KO_VERSION=$(curl -s https://api.github.com/repos/KubeOperator/KubeOperator/releases/latest | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g')
    if [ ! -z `echo ${target}|grep -Eo "v([0-9]{1,}\.)+[0-9]{1,}"` ];then
     LATEST_KO_VERSION=${target}
    fi
    export KO_INSTALL_URL="https://github.com/KubeOperator/KubeOperator/releases/download/${LATEST_KO_VERSION}/installer-${LATEST_KO_VERSION}.tar.gz"
    export KO_ANSIBLE_URL="https://github.com/KubeOperator/KubeOperator/releases/download/${LATEST_KO_VERSION}/ansible-${LATEST_KO_VERSION}.tar.gz"
    export KO_NEXUS_URL="https://kubeoperator.fit2cloud.com/nexus/nexus-${LATEST_KO_VERSION}.tar.gz"

    colorMsg $yellow "\n 提示:在线升级请确保当前主机可以正常连接互联网,升级前会先停止KubeOperator服务" | tee -a ${CWD}/upgrade.log
    if read -p  "升级操作将会升级到目标版本: $LATEST_KO_VERSION,是否继续 [y/n]: " yn;then
       if [ "$yn" == "Y" ] || [ "$yn" == "y" ] || [ "$target" == "-y" ];then
          colorMsg $green "... 停止KubeOperator服务" | tee -a ${CWD}/upgrade.log
          koctl stop

          dir_name="${CWD}/kubeoperator-upgrade-$LATEST_KO_VERSION"
          rm -rf $dir_name | tee -a ${CWD}/upgrade.log
          mkdir -p $dir_name | tee -a ${CWD}/upgrade.log

          # download
          wget --no-check-certificate "${KO_INSTALL_URL}" -P $dir_name | tee -a ${CWD}/upgrade.log
          wget --no-check-certificate "${KO_ANSIBLE_URL}" -P $dir_name| tee -a ${CWD}/upgrade.log
          wget --no-check-certificate "${KO_NEXUS_URL}" -P $dir_name| tee -a ${CWD}/upgrade.log

          # untar
          tar zxf $dir_name/installer-${LATEST_KO_VERSION}.tar.gz -C $dir_name | tee -a ${CWD}/upgrade.log
          rm -rf  $KO_BASE/kubeoperator/data/nexus-data
          tar zxf $dir_name/nexus-${LATEST_KO_VERSION}.tar.gz -C $KO_BASE/kubeoperator/data | tee -a ${CWD}/upgrade.log
          tar zxf $dir_name/ansible-${LATEST_KO_VERSION}.tar.gz -C $dir_name  | tee -a ${CWD}/upgrade.log
          sed -i -e "1,9s#KO_BASE=.*#KO_BASE=${KO_BASE}#g" $dir_name/installer/koctl | tee -a ${CWD}/upgrade.log
          \cp -rf $dir_name/installer/koctl /usr/local/bin | tee -a ${CWD}/upgrade.log

          # copy
          \cp -rf $dir_name/ansible/* $KO_BASE/kubeoperator/data/kobe/project/ko | tee -a ${CWD}/upgrade.log

          # 删除老版本遗留文件
          if [[ -d $KO_BASE/kubeoperator/conf/my.cnf ]]; then
            rm -rf $KO_BASE/kubeoperator/conf/my.cnf | tee -a ${CWD}/upgrade.log
            rm -rf $KO_BASE/kubeoperator/conf/my.conf | tee -a ${CWD}/upgrade.log
          fi
          \cp -rf $dir_name/installer/kubeoperator/conf/* $KO_BASE/kubeoperator/conf/ | tee -a ${CWD}/upgrade.log
          \cp -rf $dir_name/installer/kubeoperator/docker-compose.yml $KO_BASE/kubeoperator/ | tee -a ${CWD}/upgrade.log
          \cp -rf $dir_name/installer/koctl $KO_BASE/kubeoperator/ | tee -a ${CWD}/upgrade.log

          # 更新kubeoperator.conf 配置文件
          sed -i -e "s#KO_TAG=.*#KO_TAG=$LATEST_KO_VERSION#g" $dir_name/installer/kubeoperator/kubeoperator.conf | tee -a ${CWD}/upgrade.log
          sed -i -e "s#KO_BASE=.*#KO_BASE=$KO_BASE#g" $dir_name/installer/kubeoperator/kubeoperator.conf | tee -a ${CWD}/upgrade.log
          sed -i -e "s#KO_PORT=.*#KO_PORT=$KO_PORT#g" $dir_name/installer/kubeoperator/kubeoperator.conf | tee -a ${CWD}/upgrade.log
          sed -i -e "s#OS_ARCH=.*#OS_ARCH=$OS_ARCH#g" $dir_name/installer/kubeoperator/kubeoperator.conf | tee -a ${CWD}/upgrade.log
          if [ $(grep -c KO_REPO_PORT $KO_BASE/kubeoperator/kubeoperator.conf) -eq '1' ];then
            sed -i -e "s#KO_REPO_PORT=.*#KO_REPO_PORT=$KO_REPO_PORT#g" $dir_name/installer/kubeoperator/kubeoperator.conf | tee -a ${CWD}/upgrade.log
            sed -i -e "s#KO_REGISTRY_PORT=.*#KO_REGISTRY_PORT=$KO_REGISTRY_PORT#g" $dir_name/installer/kubeoperator/kubeoperator.conf | tee -a ${CWD}/upgrade.log
            sed -i -e "s#KO_REGISTRY_HOSTED_PORT=.*#KO_REGISTRY_HOSTED_PORT=$KO_REGISTRY_HOSTED_PORT#g" $dir_name/installer/kubeoperator/kubeoperator.conf | tee -a ${CWD}/upgrade.log
          fi
          \cp -rf $dir_name/installer/kubeoperator/kubeoperator.conf ${KO_BASE}/kubeoperator/kubeoperator.conf
          sed -i -e "1,7s#KO_BASE=.*#KO_BASE=$KO_BASE#g" $dir_name/installer/kubeoperator/scripts/const.sh | tee -a ${CWD}/upgrade.log
          \cp -rf $dir_name/installer/kubeoperator/scripts/* ${KO_BASE}/kubeoperator/scripts/

          colorMsg $yellow " ... 拉取镜像" | tee -a ${CWD}/upgrade.log
          ${KO_BASE}/kubeoperator/koctl pull | tee -a ${CWD}/upgrade.log
          ${KO_BASE}/kubeoperator/koctl start | tee -a ${CWD}/upgrade.log
          ${KO_BASE}/kubeoperator/koctl status | tee -a ${CWD}/upgrade.log
          if [ $(docker ps -a|grep kubeoperator|wc -l) -gt 0 ] && [ $(docker ps -a|grep kubeoperator |egrep "Exit|unhealthy"|wc -l) -eq 0 ];then
            colorMsg $green "升级完成，当前版本: $LATEST_KO_VERSION" | tee -a ${CWD}/upgrade.log
          else
            colorMsg $red "升级失败, 请重新执行升级命令. # koctl upgrade" | tee -a ${CWD}/upgrade.log
          fi
        else
          exit 0
       fi
       else
          exit 0
    fi  
}

function offline_upgrade() {
     colorMsg $green "... 停止KubeOperator服务" | tee -a ${CWD}/upgrade.log
     koctl stop | tee -a ${CWD}/upgrade.log
     colorMsg $green "... 加载镜像" | tee -a ${CWD}/upgrade.log
     cd  $CURRENT_DIR
     for i in ${CWD}/images/*.tar; do
         [[ -e "$i" ]] || break
        docker load -i $i 2>&1 | tee -a ${CWD}/upgrade.log
     done

     colorMsg $green "... 解压离线包" | tee -a ${CWD}/upgrade.log
     sed -i -e "1,9s#KO_BASE=.*#KO_BASE=${KO_BASE}#g" ${CWD}/koctl
     \cp -rf ${CWD}/koctl /usr/local/bin | tee -a ${CWD}/upgrade.log
     rm -rf  $KO_BASE/kubeoperator/data/nexus-data
     tar zxf ${CWD}/nexus-data.tar.gz -C $KO_BASE/kubeoperator/data | tee -a ${CWD}/upgrade.log
     rm -rf $KO_BASE/kubeoperator/data/kobe/project/ko/*

     # 删除老版本遗留文件
     if [[ -d $KO_BASE/kubeoperator/conf/my.cnf ]]; then
       rm -rf $KO_BASE/kubeoperator/conf/my.cnf
       rm -rf $KO_BASE/kubeoperator/conf/my.conf
     fi
     \cp -rf ${CWD}/kubeoperator/conf/* $KO_BASE/kubeoperator/conf/ | tee -a ${CWD}/upgrade.log
     \cp -rf ${CWD}/kubeoperator/docker-compose.yml $KO_BASE/kubeoperator | tee -a ${CWD}/upgrade.log
     \cp -rf ${CWD}/kubeoperator/data/kobe/project/ko/* $KO_BASE/kubeoperator/data/kobe/project/ko

     # 更新kubeoperator.conf 配置文件
     sed -i -e "s#KO_TAG=.*#KO_TAG=$OFFLINE_KO_VERSION#g" ${CWD}/kubeoperator/kubeoperator.conf | tee -a ${CWD}/upgrade.log
     sed -i -e "s#KO_BASE=.*#KO_BASE=$KO_BASE#g" ${CWD}/kubeoperator/kubeoperator.conf | tee -a ${CWD}/upgrade.log
     sed -i -e "s#KO_PORT=.*#KO_PORT=$KO_PORT#g" ${CWD}/kubeoperator/kubeoperator.conf | tee -a ${CWD}/upgrade.log
     sed -i -e "s#OS_ARCH=.*#OS_ARCH=$OS_ARCH#g" ${CWD}/kubeoperator/kubeoperator.conf | tee -a ${CWD}/upgrade.log
     if [ $(grep -c KO_REPO_PORT $KO_BASE/kubeoperator/kubeoperator.conf) -eq '1' ];then
      sed -i -e "s#KO_REPO_PORT=.*#KO_REPO_PORT=$KO_REPO_PORT#g" ${CWD}/kubeoperator/kubeoperator.conf | tee -a ${CWD}/upgrade.log
      sed -i -e "s#KO_REGISTRY_PORT=.*#KO_REGISTRY_PORT=$KO_REGISTRY_PORT#g" ${CWD}/kubeoperator/kubeoperator.conf | tee -a ${CWD}/upgrade.log
      sed -i -e "s#KO_REGISTRY_HOSTED_PORT=.*#KO_REGISTRY_HOSTED_PORT=$KO_REGISTRY_HOSTED_PORT#g" ${CWD}/kubeoperator/kubeoperator.conf | tee -a ${CWD}/upgrade.log
     fi
     \cp -rf ${CWD}/kubeoperator/kubeoperator.conf ${KO_BASE}/kubeoperator/kubeoperator.conf
     sed -i -e "1,7s#KO_BASE=.*#KO_BASE=$KO_BASE#g" ${CWD}/kubeoperator/scripts/const.sh | tee -a ${CWD}/upgrade.log
     \cp -rf ${CWD}/kubeoperator/scripts/* ${KO_BASE}/kubeoperator/scripts/

     ${CWD}/koctl start
     colorMsg $green "升级完成，当前版本: $OFFLINE_KO_VERSION" | tee -a ${CWD}/upgrade.log
}

function upgrade_init() {
    if [[ ! -d ${KO_BASE}/kubeoperator/scripts ]];then
      mkdir -p ${KO_BASE}/kubeoperator/scripts
    fi
}

function main() {
    upgrade_init
    if read -p "是否执行备份，(若已经备份成功可跳过此步骤) [y/n]: " yn;then
      if [ "$yn" == "Y" ] || [ "$yn" == "y" ];then
        koctl backup | tee -a ${CWD}/upgrade.log
      else
        echo "... 跳过备份" | tee -a ${CWD}/upgrade.log
      fi
    fi
    if [[ -d ${CWD}/images ]] && [[ -f ${CWD}/nexus-data.tar.gz ]]; then
          echo "离线安装"
          offline_upgrade
    else
          echo "在线安装"
          online_upgrade
    fi
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
  main
fi