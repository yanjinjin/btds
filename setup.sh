#!/bin/bash

set -x

echo "install depentent"

yum -y install lrzsz
yum -y install wget
yum -y install gdb
yum -y install ntp
yum -y install bc
yum -y install syslog
yum -y install gcc
yum -y install ncurses-devel
yum -y install libnet libnet-devel pcre pcre-devel gcc gcc-c++ automake autoconf libtool make libyaml libyaml-devel zlib zlib-devel file-devel libcap-ng-devel
yum -y install mysql-devel
yum -y install unzip
yum -y install byacc
yum -y install flex
yum -y install libxslt-devel libxml2-devel gdbm-devel libffi-devel readline-devel curl-devel openssl-devel git memcached-devel valgrind-devel ImageMagick-devel
yum -y install libpcap-devel

echo "copy etc"

cd ~
unzip etc.zip
cp etc / -rf
ldconfig
source /etc/profile

echo "install kernel and pfring"
cd ~
tar -zxvf linux-2.6.32-431.el6.tar.gz 
cp linux-2.6.32-431.el6 /usr/src/kernels/ -rf
rm /lib/modules/2.6.32-431.el6.x86_64/build -rf
ln -s /usr/src/kernels/linux-2.6.32-431.el6/ /lib/modules/2.6.32-431.el6.x86_64/build

cd ~
wget http://sourceforge.net/projects/ntop/files/PF_RING/Old/PF_RING-6.0.2.tar.gz
tar -zxvf PF_RING-6.0.2.tar.gz
cd PF_RING-6.0.2/kernel
make && make install

cd ~
wget http://archive.kernel.org/centos-vault/6.5/os/Source/SPackages/numactl-2.0.7-8.el6.src.rpm
rpm -ivh numactl-2.0.7-8.el6.src.rpm 
cd rpmbuild/SOURCES
tar -zxvf numactl-2.0.7.tar.gz 
cd numactl-2.0.7
make&&make install

cd ~
cd PF_RING-6.0.2/userland/lib
chmod +x ./configure
./configure --prefix=/usr/local/pfring 
make && make install

cd ~
cd PF_RING-6.0.2/drivers/PF_RING_aware/intel/ixgbe/ixgbe-3.21.2-zc/src/
#make && make install

echo "install mysql"

yum -y install mysql mysql-server
/etc/init.d/mysqld start
sleep 2
mysqladmin -uroot password "SJTUsec-BTDS"

echo "install ruby on rails"

cd ~
curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -
curl -sSL https://get.rvm.io | bash -s stable
/usr/local/rvm/bin/rvm install 1.9.3

gem sources --remove http://rubygems.org/
gem sources --remove https://rubygems.org/
gem sources -a http://ruby.taobao.org/
gem install rails


#############################################################################################

echo "install suricata"

cd ~
wget http://prdownloads.sourceforge.net/libdnet/libdnet-1.11.tar.gz
tar -zxvf libdnet-1.11.tar.gz 
cd libdnet-1.11
chmod +x ./configure
./configure 
make && make install

cd ~
wget http://www.digip.org/jansson/releases/jansson-2.7.tar.gz
tar -zxvf jansson-2.7.tar.gz
cd jansson-2.7
chmod +x ./configure
./configure 
make && make install

cd ~
unzip suricata-2.0.7.zip
cd suricata-2.0.7
chmod +x ./configure
LIBS="-lrt -lnuma" ./configure  --prefix=/usr  --sysconfdir=/etc  --localstatedir=/var --enable-pfring --with-libpfring-includes=/usr/local/pfring/include --with-libpfring-libraries=/usr/local/pfring/lib --with-libjansson=/usr/local/lib --with-libjansson-includes=/usr/local/include
chmod +x ./scripts/suricatasc/setup.py
make && make install
mkdir /var/log/suricata/

echo "install barnyard2"

cd ~
wget http://downloads.sourceforge.net/project/snort/OLD%20STUFF%20THAT%20YOU%20SHOULDNT%20USE/daq-2.0.2.tar.gz
tar -zxvf daq-2.0.2.tar.gz
cd daq-2.0.2
chmod +x ./configure
./configure
make && make install

cd ~
unzip barnyard2-master.zip
cd barnyard2-master
./autogen.sh
chmod +x ./configure
./configure --with-mysql --with-mysql-libraries=/usr/lib64/mysql
make && make install
mkdir /var/log/barnyard2
touch /var/log/suricata/bookmarking

echo "install snorby"

cd ~
unzip snorby.zip
cp snorby /root/ -rf
cd /root/snorby
bundle install
rake snorby:setup
chmod +x ./script/delayed_job
chmod +x ./script/rails
chmod +x ./shell/*

echo "install ttbot_zebra"

cd ~
unzip ttbot_zebra.zip
cd ttbot_zebra
chmod +x ./configure
./configure && make
 
cp ./install_zebra/conf_zebra/vtysh.conf /usr/local/etc -rf
cp ./vtysh/tpn_vtysh /bin/btds_vtysh -rf

echo "install tcpdump"
cd ~
yum -y remove libpcap-devel
cd PF_RING-6.0.2/userland/libpcap-1.1.1-ring
chmod +x ./configure
./configure --prefix=/usr/local/pfring 
make && make install

cd ~
cd PF_RING-6.0.2/userland/tcpdump-4.1.1/
chmod +x ./configure
./configure
make && make install

echo "install watchdog"

cd ~
cp ./app_watchdog /usr/bin/
chmod a+x /usr/bin/app_watchdog

echo "get rules"

cd /etc/suricata/rules
python ./spider.py
python ./sid-msg.map.py


echo "mysql update"

cd -
barnyard2 -c /etc/suricata/barnyard2.conf -d /var/log/suricata/ -f unified2.alert &
sleep 2
mysql -uroot -pSJTUsec-BTDS snorby < ./mysql_update.sql

#last do
#chsh -s /bin/btds_vtysh 
#vi /etc/sysconfig/network-scripts/ifcfg-eth6
#clear......
#rm ~/* -rf
#rm /usr/src/kernels/linux-2.6.32-431.el6 -rf
#vi /usr/bin/app_watchdog
