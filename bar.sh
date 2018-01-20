#!/bin/bash
function humanTime {
  local t=$1
  local d=$((t/60/60/24))
  local h=$((t/60/60%24))
  local m=$((t/60%60))
  local s=$((t%60))
  (( $d > 0 )) && printf '%dd ' $d
  (( $d > 0 || $h > 0 )) && printf '%02d:' $h
  printf '%02d:' $m
  printf '%02d' $s
}

# get input
title="$1"
progress=$2
startTime=$3
width=$4
sleep 1
# get readable information
percentage=`echo "($progress*100+0.5)/1" | bc` #/1是为了不保留小数（scale只对除法有用）。+0.5是四舍五入（bc默认去掉小数）。
elapsedTime=$(($SECONDS - $startTime))
if [ $progress == "0" ]; then
	estiTimeHuman="-"
else
	estiTime=`echo "$elapsedTime/$progress" | bc` 
	estiTimeHuman=`humanTime estiTime`
fi
elapsedTimeHuman=`humanTime elapsedTime`

# get length
beforeBar="$title $percentage% ["
afterBar="] $elapsedTimeHuman/$estiTimeHuman"
beforeBarLen=`echo ${#beforeBar}`
afterBarLen=`echo ${#afterBar}`

# get bar
barMaxLen=$(($width-$beforeBarLen-$afterBarLen-2))
barLen=$(( barMaxLen < 40 ? barMaxLen : 40 ))
doneLen=`echo "($barLen*$2+0.5)/1" | bc`
leftLen=`echo "($barLen*(1-$2)+0.5)/1" | bc`
done=`head -c $doneLen /dev/zero |tr '\0' '#'`
left=`head -c $leftLen /dev/zero |tr '\0' ' '`

# print the bar
echo "$beforeBar""$done""$left""$afterBar"



