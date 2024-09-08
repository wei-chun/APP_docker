#!/bin/bash

_log=$(docker logs --tail 1 naughty_poincare)
echo "["`date "+%F %T"`"]" $_log | tee -a pawns_check.log

if [[ $_log == *"could_not_mark_peer_alive"* ]]; then
  echo "["`date "+%F %T"`"]" "Pawns is disconnected. Try to reconnect it." | tee -a pawns_check.log
  _connectCMD=$(synowebapi --exec api=SYNO.Docker.Container version=1 method=stop name="naughty_poincare" && sleep 5 && docker container start naughty_poincare)
  echo "["`date "+%F %T"`"]" $_connectCMD | tee -a pawns_check.log
  sleep 60
  _log2=$(docker logs --tail 2 naughty_poincare)
  echo "["`date "+%F %T"`"]" $_log2 | tee -a pawns_check.log
  while [[ $_log2 != *"running"* ]]
  do
    echo "["`date "+%F %T"`"]" "Pawns connect failure. Try to reconnect it." | tee -a pawns_check.log
    _reconnectCMD=$(synowebapi --exec api=SYNO.Docker.Container version=1 method=stop name="naughty_poincare" && sleep 5 && docker container start naughty_poincare)
    echo "["`date "+%F %T"`"]" $_reconnectCMD | tee -a pawns_check.log
    sleep 60
    _log2=$(docker logs --tail 2 naughty_poincare)
    echo "["`date "+%F %T"`"]" $_log2 | tee -a pawns_check.log
  done
  echo "["`date "+%F %T"`"]" "Pawns connect success." | tee -a pawns_check.log
else 
  echo "["`date "+%F %T"`"]" "Pawns is connected." | tee -a pawns_check.log
fi
