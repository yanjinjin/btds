#!/bin/sh  

rows=$(df -T | grep 'ext4' | awk 'END {print NR}')
used=0
total=0
for((i=1;i<=$rows;i++))
do
  temp=$(df -T | grep 'ext4' | awk 'NR==rn {print $4}' rn=$i)
  used=`expr $used + $temp`
  temp=$(df -T | grep 'ext4' | awk 'NR==rn {print $3}' rn=$i)
  total=`expr $total + $temp`
done
RATE=`expr $used/$total*100 |bc -l`  
Disp_Rate=`expr "scale=1; $RATE/1" |bc` 
echo $Disp_Rate
