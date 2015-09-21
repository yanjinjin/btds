#!/bin/sh
#全局变量
#已配置信息的网卡个数
ETHNUM=0
#网卡名称信息，多个网卡用#符号分隔
ETHS=""
#网卡IP/掩码/默认网关信息，用:符号分隔，多个网卡用#符号分隔
ETHINFO=""
#网卡名称信息，用数组存储
ETHSArray[0]=""
#网卡IP/掩码/默认网关信息，用数组存储
ETHINFOArray[0]=""
#修改IP时原IP所在网卡在数组中的索引
ETHINDEX=0
function getIP
{
    typeset ethList="";
    typeset ethaddr="";
    typeset ethmask="";
    typeset gateway="";
    typeset ethinfo="";
    typeset ethmac="";
    typeset speed="";
    typeset status="";
    typeset iseth="";
    # 获取所有网卡信息
    ethList=`ifconfig -a | grep 'eth' | awk '{print $1}'`
    # 获取网卡默认网关
    # gateway=`route ${eth}| grep default.*UG.*$eth | awk '{print $2}'`
    gateway=`route | grep default.*UG.*$eth | awk '{print $2}'`
    # 循环所有网卡
    for eth in ${ethList}
    do
      # 获取网卡IP地址
      iseth=${eth}
      ethaddr=`ifconfig ${eth} | grep 'inet addr:'| awk '{print $2}' | awk -F : '{print $2}'`
      # 网卡配置了IP地址
      if [ "-$ethaddr" != "-" ]
      then
        # 获取网卡掩码
        ethmask=`ifconfig ${eth} | grep 'inet addr:'| awk '{print $4}' | awk -F : '{print $2}'`
        ethmac=`ifconfig ${eth} | grep 'HWaddr'| awk '{print $5}'`
        speed=`ethtool ${eth} |grep Speed |awk '{print $2}'`
        status=`ethtool ${eth} |grep "Link detected" | awk '{print $3}'`
       
        # 将该网卡的信息拼成字符串
        ethinfo="${iseth},${ethaddr},${ethmask},${gateway},${ethmac},${speed},${status}"

        ETHSArray[$ETHNUM]="$eth"
        ETHINFOArray[$ETHNUM]="$ethinfo"
        ETHNUM=`expr $ETHNUM + 1`

        # ETHS为空字符串
        if [ "-$ETHS" == "-" ]
        then
            ETHS="${eth}"
        else
            ETHS="${ETHS}#${eth}"
        fi

        # ETHINFO为空字符串
        if [ "-$ETHINFO" == "-" ]
        then
            ETHINFO="${ethinfo}"
        else
            ETHINFO="${ETHINFO}#${ethinfo}"
        fi

      fi

    done

    return 0
}

function modifyIP
{
    # 保证输入4个参数
    if [ $# -ne 4 ]; then
        echo "The parameters is not 4!"
        return 1
    fi

    typeset oldIP=$1
    typeset newIP=$2
    typeset newmask=$3
    typeset newgw=$4

    # 获取当前网卡信息
    getIP

    # 判断该原IP是否存在
    get_eth_of_IP $oldIP
    # 原IP不存在，返回1
    if [ $? -ne 0 ]; then
        echo "The old IP $oldIP is not exist."
        return 1
    fi

    typeset eth="${ETHSArray[$ETHINDEX]}"
    typeset ethinfo="${ETHINFOArray[$ETHINDEX]}"
    typeset ethaddr=`echo $ethinfo | awk -F: '{print $1}'`
    typeset ethmask=`echo $ethinfo | awk -F: '{print $2}'`
    typeset ethgw=`echo $ethinfo | awk -F: '{print $3}'`

    # 即时生效方式修改IP
    echo "ifconfig $eth $newIP netmask $newmask"
    ifconfig $eth $newIP netmask $newmask
    if [ "$?" -ne 0 ]; then
        echo "Modify old IP $oldIP to new IP $newIP failed."
        return 1
    fi

    # 永久生效方式修改IP
    sed "s/$oldIP/$newIP/" /etc/sysconfig/network/ifcfg-$eth > /tmp/ifcfgtemp
    sed "s/$ethmask/$newmask/" /tmp/ifcfgtemp > /etc/sysconfig/network/ifcfg-$eth
    rm /tmp/ifcfgtemp

    #即时生效方式修改网关
    route del default
    echo "route del default"
    route add default gw $newgw dev $eth
    echo "route add default gw $newgw dev $eth"

    # 永久生效方式修改网关
    sed "s/$ethgw/$newgw/" /etc/sysconfig/network/routes > /tmp/routetemp
    mv /tmp/routetemp /etc/sysconfig/network/routes

    return 0
}
###############################################################
#函数名称：get_eth_of_IP
#功    能：获取IP所在网卡的索引
#输入参数：IP
#返回值：1 没有设置该IP的网卡，0 设置该IP的网卡所在索引。
#        2 传入参数错误
#        ETHINDEX值为索引位置
#
###############################################################
function get_eth_of_IP
{
    # 保证输入一个参数
    if [ $# -ne 1 ]; then
        echo "The parameters is not 1!"
        return 2
    fi

    typeset oldIP=$1
    typeset ethaddr=""
    typeset ethinfo=""
    typeset index=0
    while [ $index -lt ${#ETHSArray[@]} ]
    do
        ethinfo="${ETHINFOArray[index]}"
        ethaddr=`echo $ethinfo | awk -F: '{print $1}'`
        if [ "${ethaddr}" == "${oldIP}" ];then
            ETHINDEX=$index
            return 0
        fi
        index=`expr $index + 1`
    done
    return 1
}

if [ $#  -eq  0 ];then
  getIP
  echo $ETHINFO
  exit 0
fi
case $1 in
getip)
  getIP
  echo $ETHINFO
  exit 0
;;
modify)
  modifyIP $2 $3 $4 $5
  exit 0
;;
esac
  echo "The parameters are invalid."
  exit 0
;;
