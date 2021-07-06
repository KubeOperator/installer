#!/usr/bin/env bash

export red=31
export green=32
export yellow=33

export KO_BASE=/opt
export CWD=$(pwd)
export BACKUP_DIR=${KO_BASE}/kubeoperator_backup
export BACKUP_FILE=${BACKUP_DIR}/kubeoperator-backup-`date +%F_%T`.tar.gz

export COMPOSE_HTTP_TIMEOUT=180
export CURRENT_KO_VERSION=`cat ${KO_BASE}/kubeoperator/kubeoperator.conf|grep KO_TAG|awk -F= '{print $2}'`
export OFFLINE_KO_VERSION=$(pwd|grep -Eo "v([0-9]{1,}\.)+[0-9]{1,}")
export KO_PORT=`cat ${KO_BASE}/kubeoperator/kubeoperator.conf |grep KO_PORT|awk -F= '{print $2}'`

function colorMsg() {
  echo -e "\033[$1m $2 \033[0m"
}