#!/bin/bash
PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin
docker container restart repocket 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a crontab.log
sleep 5
docker container restart proxyrack 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a /crontab.log
sleep 5
earnapp stop 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a /home/dangel/crontab.log
sleep 5
earnapp start 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a /home/dangel/crontab.log
