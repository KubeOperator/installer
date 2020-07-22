#Install Latest Stable KubeOperator Release


# 1.检测 docker 是否存在
if which docker docker-compose ;then
  echo "docker 已经安装，跳过安装步骤"
  if systemctl status docker|grep running;then
    echo "docker 运行正常"
  else
    echo "docker 已经安装，跳过安装步骤"
  fi
else
  mkdir -p /etc/yum.repos.d /bak
  mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/bak
  wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo 2&> /dev/null
  wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo 2&> /dev/null
  yum install docker  -y
  systemctl start docker
fi

#  2.启动 kubeoperator
echo "开始启动 KubeOperator"
cd /opt/installer/kubeoperator/ && docker-compose up -d
if [ $? = 0 ];then
echo -e "======================= KubeOperator 安装完成 =======================\n" 2>&1
echo -e "======================= 默认用户名： admin     =======================\n" 2>&1
echo -e "======================= 默认密码： kubeoperator@admin123 =============\n" 2>&1
fi
