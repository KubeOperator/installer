#!/usr/bin/env bash

source "${KO_BASE}/kubeoperator/scripts/const.sh"

function backup() {
  koctl stop
  mkdir -p $BACKUP_DIR
  cd ${KO_BASE}
  colorMsg $yellow "... 开始备份,数据文件较大，请耐心等待，保持终端在线" | tee -a ${CWD}/upgrade.log
  sleep 5s
  if tar zcvf $BACKUP_FILE kubeoperator 1>/dev/null;then
  koctl start
  colorMsg $green "备份完成,备份文件存放至: $BACKUP_FILE" | tee -a ${CWD}/upgrade.log
  else
  colorMsg $red "备份失败，请重新备份" | tee -a ${CWD}/upgrade.log
  fi
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
  backup
fi