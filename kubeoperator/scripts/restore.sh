#!/usr/bin/env bash

source "${KO_BASE}/kubeoperator/scripts/const.sh"

function restore() {
  koctl stop| tee -a ${CWD}/upgrade.log
  mv -n ${KO_BASE}/kubeoperator ${KO_BASE}/kubeoperator-bak | tee -a ${CWD}/upgrade.log
  colorMsg $yellow "... 开始恢复" | tee -a ${CWD}/upgrade.log
  tar zxvf $target -C ${KO_BASE}/ 1>/dev/null | tee -a ${CWD}/upgrade.log
  if [ $? -eq 0 ];then
    koctl start
    colorMsg $green "恢复完成" | tee -a ${CWD}/upgrade.log
  else
    colorMsg $red "恢复失败，$target 解压异常" | tee -a ${CWD}/upgrade.log
  fi
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
  restore
fi