#!/usr/bin/env bash

source "${KO_BASE}/kubeoperator/scripts/const.sh"

function success(){
    echo -e "\033[32m KubeOperator 卸载完成. \033[0m"
}

function remove_dir() {
    echo -e "删除 KubeOperator 工作目录"
    rm -rf ${KO_BASE}/kubeoperator 2&> /dev/null
}

function remove_service() {
    if [ -a ${KO_BASE}/kubeoperator/docker-compose.yml ]; then
      read -p "卸载将会完全清除 KubeOperator 的所有容器和数据，是否继续 [y/n] : " yn
      if [ "$yn" == "Y" ] || [ "$yn" == "y" ]; then
      echo -e "停止 KubeOperator 服务进程"
      cd ${KO_BASE}/kubeoperator && docker-compose down -v
      rm -rf /usr/local/bin/koctl
      else
      exit 0
      fi
    fi
}

function remove_images() {
    echo -e "清理镜像中..."
    docker images -q|xargs docker rmi -f 2&> /dev/null
}

function main() {
    remove_service
    remove_images
    remove_dir
    success
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
  main
fi