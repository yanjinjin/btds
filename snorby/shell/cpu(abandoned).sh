#!/bin/sh  
str=$(ps -aux |  awk '$3!=0.0 &&NR!=1 {print $3}')
n=$(echo $str | awk '{print NF}')
total=0
for((i=1;i<=$n;i++))
do
  temp=$(echo $str | awk '{print $num*100}' num=$i)
  total=$(expr $total + $temp | bc)
done
echo $total
