#!/bin/sh
mysqldump -uroot -pSJTUsec-BTDS snorby logs > /root/snorby/public/logsbackup/logs_backup`date +%Y%m%d%H%M%S`.sql
