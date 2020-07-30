#!/usr/bin/env bash
#Install Latest Stable KubeOperator Release

red=31
green=32
yellow=33
blue=34

function colorMsg()
{
  echo -e "\033[$1m $2 \033[0m"
}

function log() {
   message="[KubeOperator Log]: $1 "
   echo -e "${message}" 2>&1 | tee -a ${CURRENT_DIR}/install.log
}

echo
cat << EOF
██╗  ██╗██╗   ██╗██████╗ ███████╗ ██████╗ ██████╗ ███████╗██████╗  █████╗ ████████╗ ██████╗ ██████╗
██║ ██╔╝██║   ██║██╔══██╗██╔════╝██╔═══██╗██╔══██╗██╔════╝██╔══██╗██╔══██╗╚══██╔══╝██╔═══██╗██╔══██╗
█████╔╝ ██║   ██║██████╔╝█████╗  ██║   ██║██████╔╝█████╗  ██████╔╝███████║   ██║   ██║   ██║██████╔╝
██╔═██╗ ██║   ██║██╔══██╗██╔══╝  ██║   ██║██╔═══╝ ██╔══╝  ██╔══██╗██╔══██║   ██║   ██║   ██║██╔══██╗
██║  ██╗╚██████╔╝██████╔╝███████╗╚██████╔╝██║     ███████╗██║  ██║██║  ██║   ██║   ╚██████╔╝██║  ██║
╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚══════╝ ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝
EOF

colorMsg $yellow "\n\n开始安装 KubeOperator，版本 - ${KO_VERSION}"

if [ ! $CURRENT_DIR ];then
  CURRENT_DIR=$(cd "$(dirname "$0")";pwd)
fi

if read -t 120 -p "设置KubeOperator安装目录,默认/opt : " KO_BASE;then
  if [ "$KO_BASE" != "" ];then
    echo "你选择的安装路径为 $KO_BASE"
  else
    KO_BASE=/opt
  fi
else
  echo "(设置超时，使用默认安装路径 /opt)"
  KO_BASE=/opt
fi


# 解压离线文件
if [ -d $CURRENT_DIR/docker ];then
# 离线安装
    cp -rp $CURRENT_DIR/kubeoperator $KO_BASE
    tar zxvf $CURRENT_DIR/ansible.tar.gz -C $CURRENT_DIR > /dev/null 2>&1
    cp -rp $CURRENT_DIR/ansible $KO_BASE/kubeoperator/data/kobe/project/ko
    cp -rp $CURRENT_DIR/koctl $KO_BASE/kubeoperator
    tar zxvf $CURRENT_DIR/nexus-data.tar.gz -C $KO_BASE/kubeoperator/data/ > /dev/null 2>&1
else
# 在线安装
    cp -rp $CURRENT_DIR/installer/kubeoperator $KO_BASE
    cp -rp $CURRENT_DIR/installer/koctl $KO_BASE
    log "解压 ansible "
    tar zxvf $CURRENT_DIR/ansible.tar.gz -C $CURRENT_DIR > /dev/null 2>&1
    cp -rp $CURRENT_DIR/ansible $KO_BASE/kubeoperator/data/kobe/project/ko
    log "解压 nexus "
    tar zxvf $CURRENT_DIR/nexus-data.origin.tar.gz -C $KO_BASE/kubeoperator/data/ > /dev/null 2>&1
fi
sed -i "s/^KO_BASE=\/opt.*/KO_BASE=\/\${KO_BASE}/g"  $KO_BASE/kubeoperator/koctl
cp -rp  $KO_BASE/kubeoperator/koctl /usr/local/bin/

# 1.检测 docker 是否存在
if which docker docker-compose ;then
  echo "docker 已经安装，跳过安装步骤"
  if systemctl status docker|grep running;then
    echo "docker 运行正常"
  else
    echo "docker 已经安装，跳过安装步骤"
  fi
else
   if [[ -d docker ]]; then
      log "... 离线安装 docker"
      cp docker/bin/* /usr/bin/
      cp docker/service/docker.service /etc/systemd/system/
      chmod +x /usr/bin/docker*
      chmod 754 /etc/systemd/system/docker.service
      log "... 启动 docker"
      systemctl start docker 2>&1 | tee -a ${CURRENT_DIR}/install.log
      systemctl enable docker 2>&1 | tee -a ${CURRENT_DIR}/install.log
   else
      log "... 在线安装 docker"
      curl -fsSL https://get.docker.com -o get-docker.sh 2>&1 | tee -a ${CURRENT_DIR}/install.log
      sudo sh get-docker.sh 2>&1 | tee -a ${CURRENT_DIR}/install.log
      log "... 在线安装 docker-compose"
      sudo curl -L "https://github.com/docker/compose/releases/download/1.26.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
      sudo chmod +x /usr/local/bin/docker-compose
      log "... 启动 docker"
      service docker start 2>&1 | tee -a ${CURRENT_DIR}/install.log
      systemctl enable docker 2>&1 | tee -a ${CURRENT_DIR}/install.log
   fi
fi

# 2.加载镜像
export COMPOSE_HTTP_TIMEOUT=180
if [[ -d $CURRENT_DIR/images ]]; then
   log "加载镜像"
   cd  $CURRENT_DIR
   for i in $(ls images); do
      docker load -i images/$i 2>&1 | tee -a ${CURRENT_DIR}/install.log
   done
else
   log "拉取镜像"
   cd $KO_BASE/kubeoperator/ && docker-compose pull 2>&1 | tee -a ${CURRENT_DIR}/install.log
   cd -
fi

#  3.启动 kubeoperator
log "开始启动 KubeOperator"
cd  $KO_BASE/kubeoperator/ && docker-compose up -d 2>&1 | tee -a ${CURRENT_DIR}/install.log
if [ $? = 0 ];then
echo -e "======================= KubeOperator 安装完成 =======================\n" 2>&1 | tee -a ${CURRENT_DIR}/install.log
echo -e "请通过以下方式访问:\n URL: \033[33m http://$(hostname -I|cut -d" " -f 1)\033[0m \n 用户名: \033[${green}m admin \033[0m \n 初始密码: \033[${green}m kubeoperator@admin123 \033[0m" 2>&1 | tee -a ${CURRENT_DIR}/install.log
fi
