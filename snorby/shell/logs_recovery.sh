#!/bin/sh
filename=$1
mysql  -uroot -pSJTUsec-BTDS snorby < /root/snorby/public/logsbackup/$filename
