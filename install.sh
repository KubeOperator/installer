#!/usr/bin/env bash
#Install Latest Stable KubeOperator Release

red=31
green=32
yellow=33
blue=34

set -e
# 检测系统架构，目前支持 arm64 和 amd64
os=`uname -a`
if [[ $os =~ 'aarch64' ]];then
  architecture="arm64"
elif [[ $os =~ 'x86_64' ]];then
  architecture="amd64"
else
  colorMsg $red "暂不支持的系统架构，请参阅官方文档，选择受支持的系统"
fi

if [ "$architecture" == "arm64" ];then
  docker_compose_version="1.22.0"
else
  docker_compose_version="1.26.2"
fi
docker_version="19.03.9"
docker_download_url="https://kubeoperator.fit2cloud.com/docker/$docker_version/$architecture/docker-$docker_version.tgz"
docker_compose_download_url="https://kubeoperator.fit2cloud.com/docker-compose/$architecture/$docker_compose_version/docker-compose"
mysql_download_url="https://kubeoperator.fit2cloud.com/mysql/$architecture/mysql.tar.gz"

function colorMsg()
{
  echo -e "\033[$1m $2 \033[0m"
}

function log() {
   message="[KubeOperator Log]: $1 "
   echo -e "${message}" 2>&1 | tee -a ${CURRENT_DIR}/install.log
}

if [ ! $KO_VERSION ];then
  KO_VERSION=$(cat kubeoperator/kubeoperator.conf|grep "KO_TAG"|awk -F= '{print $2}')
fi

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

# 配置 kubeoperator
function set_dir() {
  if read -t 120 -p "设置KubeOperator安装目录,默认/opt: " KO_BASE;then
  if [ "$KO_BASE" != "" ];then
    echo "你选择的安装路径为 $KO_BASE"
    if [ ! -d $KO_BASE ];then
      mkdir -p $KO_BASE
    fi
  else
    KO_BASE=/opt
    echo "你选择的安装路径为 $KO_BASE"
  fi
  else
    KO_BASE=/opt
    echo "(设置超时，使用默认安装路径 /opt)"
  fi
}

# 解压离线文件
function unarchive() {
  if [ -d ${CURRENT_DIR}/docker ];then
      # 离线安装
      log "... 解压离线包"
      \cp -rfp ${CURRENT_DIR}/kubeoperator $KO_BASE
      \cp -rfp ${CURRENT_DIR}/koctl $KO_BASE/kubeoperator
      tar zxf ${CURRENT_DIR}/nexus-data.tar.gz -C $KO_BASE/kubeoperator/data/ > /dev/null 2>&1
      log "... 解压 mysql 初始化文件"
      tar zxf ${CURRENT_DIR}/mysql.tar.gz -C $KO_BASE/kubeoperator/data/ > /dev/null 2>&1
  else
      # 在线安装
      \cp -rfp ${CURRENT_DIR}/kubeoperator-release-${KO_VERSION}/installer/kubeoperator $KO_BASE
      \cp -rfp ${CURRENT_DIR}/kubeoperator-release-${KO_VERSION}/installer/koctl $KO_BASE/kubeoperator
      log "... 解压 ansible "
      tar zxf ${CURRENT_DIR}/kubeoperator-release-${KO_VERSION}/ansible-${KO_VERSION}.tar.gz -C ${CURRENT_DIR}/kubeoperator-release-${KO_VERSION} > /dev/null 2>&1
      \cp -rfp ${CURRENT_DIR}/kubeoperator-release-${KO_VERSION}/ansible $KO_BASE/kubeoperator/data/kobe/project/ko
      log "... 解压 nexus "
      tar zxf ${CURRENT_DIR}/kubeoperator-release-${KO_VERSION}/nexus-${KO_VERSION}.tar.gz -C $KO_BASE/kubeoperator/data/ > /dev/null 2>&1
      sed -i -e "s#KO_TAG=.*#KO_TAG=$KO_VERSION#g" $KO_BASE/kubeoperator/kubeoperator.conf
      sed -i -e "s#OS_ARCH=.*#OS_ARCH=$architecture#g" $KO_BASE/kubeoperator/kubeoperator.conf
      log "... 下载、解压 mysql 初始化文件"
      wget --no-check-certificate $mysql_download_url -P ${CURRENT_DIR}/kubeoperator-release-${KO_VERSION}/ | tee -a ${CURRENT_DIR}/install.log
      tar zxf ${CURRENT_DIR}/kubeoperator-release-${KO_VERSION}/mysql.tar.gz -C $KO_BASE/kubeoperator/data/ | tee -a ${CURRENT_DIR}/install.log
  fi
  log "... 创建 grafana 持久化目录"
  mkdir -p $KO_BASE/kubeoperator/data/grafana
  sudo chown -R 472:472 $KO_BASE/kubeoperator/data/grafana
  # 拷贝 koctl 可执行文件
  sed -i -e "1,9s#KO_BASE=.*#KO_BASE=${KO_BASE}#g" $KO_BASE/kubeoperator/koctl
  \cp -rfp  $KO_BASE/kubeoperator/koctl /usr/local/bin/
}

function ko_config() {
   sed -i -e "s#KO_BASE=.*#KO_BASE=$KO_BASE#g" $KO_BASE/kubeoperator/kubeoperator.conf
   if [ ! -f $KO_BASE/kubeoperator/.env ];then
     ln -s $KO_BASE/kubeoperator/kubeoperator.conf $KO_BASE/kubeoperator/.env
   fi
}

# 配置docker，私有 docker 仓库授信
function config_docker() {
  if [ $(getenforce) == "Enforcing" ];then
    log  "... 关闭 SELINUX"
    setenforce 0
    sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
  fi
  log  "... 关闭 Firewalld"
  systemctl stop firewalld | tee -a ${CURRENT_DIR}/install.log
  systemctl disable firewalld | tee -a ${CURRENT_DIR}/install.log
  if ! grep registry.kubeoperator.io /etc/hosts;then
    log  "... 添加 kubeoperator docker 仓库"
    echo "127.0.0.1 registry.kubeoperator.io" >> /etc/hosts
  fi
  if [ -r /etc/docker/daemon.json ];then
    mv -n /etc/docker/daemon.json /etc/docker/daemon.json.bak
  else
    mkdir -p /etc/docker
  fi
cat << EOF > /etc/docker/daemon.json
{
  "registry-mirrors": ["http://registry.kubeoperator.io:8082","http://registry.kubeoperator.io:8083"],
  "insecure-registries": ["registry.kubeoperator.io:8082","registry.kubeoperator.io:8083"],
  "max-concurrent-downloads": 10,
  "log-driver": "json-file",
  "log-level": "warn",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
  }
EOF
  systemctl daemon-reload | tee -a ${CURRENT_DIR}/install.log
  systemctl restart docker | tee -a ${CURRENT_DIR}/install.log
}

# 检测 docker 是否存在
function install_docker() {
  if which docker docker-compose ;then
    log "... docker 已经安装，跳过安装步骤"
    config_docker
    if systemctl status docker|grep running;then
      log "... docker 运行正常"
    else
      log "... docker 已经安装，跳过安装步骤"
    fi
  else
   if [[ -d docker ]]; then
      log "... 离线安装 docker"
      cp docker/bin/* /usr/bin/
      cp docker/service/docker.service /etc/systemd/system/
      sudo chmod +x /usr/bin/docker*
      sudo chmod 754 /etc/systemd/system/docker.service
      log "... 配置 docker"
      config_docker
      log "... 启动 docker"
      systemctl start docker 2>&1 | tee -a ${CURRENT_DIR}/install.log
      systemctl enable docker 2>&1 | tee -a ${CURRENT_DIR}/install.log
   else
      log "... 在线安装 docker"
      wget --no-check-certificate  $docker_download_url -P ${CURRENT_DIR}/kubeoperator-release-${KO_VERSION}| tee -a ${CURRENT_DIR}/install.log
      tar zxf ${CURRENT_DIR}/kubeoperator-release-${KO_VERSION}/docker-$docker_version.tgz -C ${CURRENT_DIR}/kubeoperator-release-${KO_VERSION}/ | tee -a ${CURRENT_DIR}/install.log
      \cp -rfp ${CURRENT_DIR}/kubeoperator-release-${KO_VERSION}/docker/* /usr/bin/ | tee -a ${CURRENT_DIR}/install.log
      \cp -rfp $KO_BASE/kubeoperator/conf/docker.service /etc/systemd/system/ | tee -a ${CURRENT_DIR}/install.log
      log "... 在线安装 docker-compose"
      wget --no-check-certificate  $docker_compose_download_url -P ${CURRENT_DIR}/kubeoperator-release-${KO_VERSION}| tee -a ${CURRENT_DIR}/install.log
      \cp -rfp ${CURRENT_DIR}/kubeoperator-release-${KO_VERSION}/docker-compose /usr/bin/ | tee -a ${CURRENT_DIR}/install.log
      sudo chmod +x /usr/bin/docker-compose
      log "... 配置 docker"
      config_docker
      log "... 启动 docker"
      service docker start 2>&1 | tee -a ${CURRENT_DIR}/install.log
      systemctl enable docker 2>&1 | tee -a ${CURRENT_DIR}/install.log
   fi
  fi
}

# 加载镜像
function load_image() {
  export COMPOSE_HTTP_TIMEOUT=180
  if [[ -d ${CURRENT_DIR}/images ]]; then
     log "... 加载镜像"
     cd  $CURRENT_DIR
     for i in $(ls images); do
        docker load -i images/$i 2>&1 | tee -a ${CURRENT_DIR}/install.log
     done
  else
     log "... 拉取镜像"
     cd $KO_BASE/kubeoperator/ && docker-compose pull 2>&1 | tee -a ${CURRENT_DIR}/install.log
     cd -
  fi
}

# 启动 kubeoperator
function ko_start() {
  # 设置 app.yaml 配置文件权限
  sudo chmod 600 $KO_BASE/kubeoperator/conf/app.yaml
  log "... 开始启动 KubeOperator"
    cd  $KO_BASE/kubeoperator/ && docker-compose up -d 2>&1 | tee -a ${CURRENT_DIR}/install.log
    sleep 15s
  while [ $(docker ps -a|grep kubeoperator|wc -l) -lt 9 ]
  do
    log "... 检测到应用程序未正常运行，尝试重新启动"
    sleep 15s
    koctl start
    break
  done
  if [ $(docker ps -a|grep kubeoperator|wc -l) -gt 0 ] && [ $(docker ps -a|grep kubeoperator |egrep "Exit|unhealthy"|wc -l) -eq 0 ];then
    echo -e "======================= KubeOperator 安装完成 =======================\n" 2>&1 | tee -a ${CURRENT_DIR}/install.log
    echo -e "请开放防火墙或安全组的80,8081-8083端口,通过以下方式访问:\n URL: \033[33m http://\$LOCAL_IP:80\033[0m \n 用户名: \033[${green}m admin \033[0m \n 初始密码: \033[${green}m kubeoperator@admin123 \033[0m" 2>&1 | tee -a ${CURRENT_DIR}/install.log
  else
    colorMsg $red "KubeOperator 服务异常，请检查服务是否启动" | tee -a ${CURRENT_DIR}/install.log
    cd  $KO_BASE/kubeoperator/ && docker-compose status
  fi
}

function main() {
  set_dir
  unarchive
  install_docker
  ko_config
  load_image
  ko_start
}

main