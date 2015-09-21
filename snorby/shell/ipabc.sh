#!/bin/sh   
# 保证输入5个参数
eth=$1
newIP=$2
newmask=$3
newgw=$5
newmac=$4

if [ "-$newgw" != "-" ]
then
    list=`find /etc/sysconfig/network-scripts -name "ifcfg-eth*"`;
    for each in ${list}
    do
	sed -i '/GATEWAY/d' $each
    done
    echo "GATEWAY=$newgw" >> /etc/sysconfig/network-scripts/ifcfg-$eth
fi

sed -i '/DEVICE/d' /etc/sysconfig/network-scripts/ifcfg-$eth
echo "DEVICE=$eth" >> /etc/sysconfig/network-scripts/ifcfg-$eth

sed -i '/ONBOOT/d' /etc/sysconfig/network-scripts/ifcfg-$eth
echo 'ONBOOT=yes' >> /etc/sysconfig/network-scripts/ifcfg-$eth

sed -i '/TYPE/d' /etc/sysconfig/network-scripts/ifcfg-$eth
echo 'TYPE=Ethernet' >> /etc/sysconfig/network-scripts/ifcfg-$eth

sed -i '/BOOTPROTO/d' /etc/sysconfig/network-scripts/ifcfg-$eth
echo 'BOOTPROTO=static' >> /etc/sysconfig/network-scripts/ifcfg-$eth

sed -i '/IPADDR/d' /etc/sysconfig/network-scripts/ifcfg-$eth
echo "IPADDR=$newIP" >> /etc/sysconfig/network-scripts/ifcfg-$eth

sed -i '/NETMASK/d' /etc/sysconfig/network-scripts/ifcfg-$eth
echo "NETMASK=$newmask" >> /etc/sysconfig/network-scripts/ifcfg-$eth

sed -i '/HWADDR/d' /etc/sysconfig/network-scripts/ifcfg-$eth
echo "HWADDR=$newmac" >> /etc/sysconfig/network-scripts/ifcfg-$eth

sed -i '/GATEWAY/d' /etc/sysconfig/network
echo "GATEWAY=$newgw" >> /etc/sysconfig/network

service network restart
