#!/bin/sh  

RAMLOG=$(free | grep 'Mem' | awk '{print $2" "$3}') 
TOTAL=$(echo $RAMLOG | awk '{print $1}') 
USED=$(echo $RAMLOG | awk '{print $2}') 
RATE=`expr $USED/$TOTAL*100 |bc -l`  
Disp_Rate=`expr "scale=1; $RATE/1" |bc` 
echo $Disp_Rate
