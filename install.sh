#Install Latest Stable KubeOperator Release
#BASE_DIR=$(cd "$(dirname "$0")";pwd)
#PROJECT_DIR=$(dirname ${BASE_DIR})
#CURRENT_DIR=$(cd "$(dirname "$0")";pwd)

if read -t 60 -p "设置KubeOperator安装目录,默认 /opt :" KO_BASE;then
  echo "你选择的安装路径为 $KO_BASE"
else
  echo "(设置超时，使用默认安装路径 /opt)"
fi

function log() {
   message="[KubeOperator Log]: $1 "
   echo -e "${message}" 2>&1 | tee -a ${CURRENT_DIR}/install.log
}

# 解压离线文件
if [ $CURRENT_DIR ] && [ -d $CURRENT_DIR/installer ];then
  echoo "在线安装"
  tar zxvf $CURRENT_DIR/ansible.tar.gz -C $CURRENT_DIR
  cp -rp $CURRENT_DIR/installer/kubeoperator $KO_BASE/
  tar zxvf $CURRENT_DIR/nexus-data.origin.tar.gz -C $KO_BASE/kubeoperator/data/
  cp -rp $CURRENT_DIR/ansible $KO_BASE/kubeoperator/data/kobe/project/ko
# 离线安装
fi

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
      service docker start 2>&1 | tee -a ${CURRENT_DIR}/install.log
   else
      log "... 在线安装 docker"
      curl -fsSL https://get.docker.com -o get-docker.sh 2>&1 | tee -a ${CURRENT_DIR}/install.log
      sudo sh get-docker.sh 2>&1 | tee -a ${CURRENT_DIR}/install.log
      log "... 在线安装 docker-compose"
      sudo curl -L "https://github.com/docker/compose/releases/download/1.26.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
      sudo chmod +x /usr/local/bin/docker-compose
      log "... 启动 docker"
      service docker start 2>&1 | tee -a ${CURRENT_DIR}/install.log
   fi
fi
#https://download.docker.com/linux/static/stable/x86_64/docker-19.03.9.tgz

cd  $CURRENT_DIR/installer
# 2.加载镜像
if [[ -d images ]]; then
   log "加载镜像"
   for i in $(ls images); do
      docker load -i images/$i 2>&1 | tee -a ${CURRENT_DIR}/install.log
   done
else
   log "拉取镜像"
   cd $KO_BASE/kubeoperator/ && docker-compose pull 2>&1 | tee -a ${CURRENT_DIR}/install.log
   docker pull ${MS_PREFIX}/jmeter-master:0.0.6 2>&1 | tee -a ${CURRENT_DIR}/install.log
   cd -
fi

#  3.启动 kubeoperator
log "开始启动 KubeOperator"
cd  $KO_BASE/kubeoperator/ && docker-compose up -d 2>&1 | tee -a ${CURRENT_DIR}/install.log
if [ $? = 0 ];then
echo -e "======================= KubeOperator 安装完成 =======================\n" 2>&1 | tee -a ${CURRENT_DIR}/install.log
echo -e "请通过以下方式访问:\n URL: \033[33m http://LOCAL_IP \033[0m \n 用户名: \033[32m admin \033[0m \n 初始密码: \033[32m kubeoperator@admin123 \033[0m" 2>&1 | tee -a ${CURRENT_DIR}/install.log
fi
