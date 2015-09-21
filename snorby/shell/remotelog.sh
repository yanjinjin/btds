#!/bin/sh   

ip=$1
port=$2

if [ "-$ip" != "-" ]
then
  if [ "#$ip" == "##" ]
  then
    sed -i '/output alert_syslog_full/d' /etc/suricata/barnyard2.conf
  else
    sed -i '/output alert_syslog_full/d' /etc/suricata/barnyard2.conf
    echo "output alert_syslog_full: sensor_name btds, server $ip, protocol udp, port $port, operation_mode default" >> /etc/suricata/barnyard2.conf
  fi
fi



