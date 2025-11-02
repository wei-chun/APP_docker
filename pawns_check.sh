#!/bin/bash

# ====================================
# 配置區塊
# ====================================
CONTAINER_NAME="naughty_poincare"
LOG_FILE="pawns_check.log"
SLEEP_TIME=60 # 重啟後等待秒數
# ====================================

echo "["`date "+%F %T"`"]" "====== 啟動 Pawns 連線檢查腳本 ======" | tee -a $LOG_FILE

# 1. 取得最後 2 行日誌，並將標準錯誤輸出也導向標準輸出 (2>&1)
_log=$(docker logs --tail 2 $CONTAINER_NAME 2>&1)
echo "["`date "+%F %T"`"]" "檢查日誌 (尾兩行):\n$_log" | tee -a $LOG_FILE

# 2. 判斷是否需要重啟：包含錯誤訊息、斷線或卡在 starting 狀態
# 精確判斷：只要日誌中包含 "not_running" 或 "starting" 或 "could_not_mark_peer_alive"
if [[ $_log == *'"name":"not_running"'* || $_log == *'"name":"starting"'* || $_log == *"could_not_mark_peer_alive"* ]]; then
  echo "["`date "+%F %T"`"]" "**Pawns 偵測到需要重啟的狀態。開始重啟程序。**" | tee -a $LOG_FILE
  
  # --- 執行第一次重啟 ---
  echo "["`date "+%F %T"`"]" "執行第一次重啟 (停止 -> 啟動)..." | tee -a $LOG_FILE
  
  # 執行停止並啟動的指令，並將輸出導向 /dev/null 避免雜亂輸出
  synowebapi --exec api=SYNO.Docker.Container version=1 method=stop name="$CONTAINER_NAME" > /dev/null 2>&1
  sleep 5 
  docker container start $CONTAINER_NAME > /dev/null 2>&1
  
  sleep $SLEEP_TIME
  
  # 取得重啟後的日誌
  _log2=$(docker logs --tail 2 $CONTAINER_NAME 2>&1)
  echo "["`date "+%F %T"`"]" "重啟後日誌檢查:\n$_log2" | tee -a $LOG_FILE
  
  # 3. 重試迴圈：持續重啟直到日誌中**精確**包含 `"name":"running"` 狀態
  # 使用 grep 判斷，避免 'not_running' 的誤判
  while ! grep -q '"name":"running"' <<< "$_log2";
  do
    
    # 增加空日誌檢查，避免無限重啟
    if [[ -z "$_log2" ]]; then
      echo "["`date "+%F %T"`"]" "**日誌為空。可能容器啟動失敗或已停止。跳出重試迴圈。**" | tee -a $LOG_FILE
      break
    fi
    
    echo "["`date "+%F %T"`"]" "**Pawns 尚未進入 running 狀態。嘗試再次重啟...**" | tee -a $LOG_FILE
    
    # 再次執行重啟
    synowebapi --exec api=SYNO.Docker.Container version=1 method=stop name="$CONTAINER_NAME" > /dev/null 2>&1
    sleep 5
    docker container start $CONTAINER_NAME > /dev/null 2>&1
    
    sleep $SLEEP_TIME
    _log2=$(docker logs --tail 2 $CONTAINER_NAME 2>&1)
    echo "["`date "+%F %T"`"]" "再次重啟後日誌檢查:\n$_log2" | tee -a $LOG_FILE
  done
  
  # 4. 判斷最終結果
  if grep -q '"name":"running"' <<< "$_log2"; then
    echo "["`date "+%F %T"`"]" "**Pawns 連線成功，已進入 running 狀態。**" | tee -a $LOG_FILE
  else
    echo "["`date "+%F %T"`"]" "**警告：重試失敗，請手動檢查容器狀態。**" | tee -a $LOG_FILE
  fi
  
else 
  # 如果日誌中沒有需要重啟的關鍵詞
  echo "["`date "+%F %T"`"]" "Pawns 正在執行中 (無錯誤)。" | tee -a $LOG_FILE
fi

echo "["`date "+%F %T"`"]" "====== 腳本執行結束 ======" | tee -a $LOG_FILE
