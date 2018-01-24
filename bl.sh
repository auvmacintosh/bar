#!/bin/bash

# 返回第一个Barline，清空后边所有行。 
function returnFirstBarLine() {
	local barLinesNo=$1
	if [[ $barLinesNo -gt 0 ]]; then # 在至少已经打印了一行bar的情况下，才return
		local barLineLen=$2
		local col=$(tput cols)
		tput cuu $(echo "$barLinesNo*($barLineLen+$col-1)/$col" | bc) # use bc to get ceil of divide/by:($divide+$by-1)/$by
		tput ed
	fi
}

# 以s为单位的时间间隔，改称人类可读格式
function humanDuration {
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

# 打印一个barline
function printBarLine() {
	# get input
	local title="$1"
	local progress=$2
	local startTime=$3
	local col=$(tput cols)

	# get readable information
	local percentage=$(echo "($progress*100+0.5)/1" | bc) #/1是为了不保留小数（scale只对除法有用）。+0.5是四舍五入（bc默认去掉小数）。
	local elapsedTime=$(($SECONDS - $startTime))
	if [[ $progress == 0?([.])*([0]) ]]; then # 允许0，0.0，0.0000这类格式
		local estiTimeHuman="-" # 允许完成度为0，为了避免除0的情况发生，执行这个分支
	else
		local estiTime=$(echo "$elapsedTime/$progress" | bc) 
		local estiTimeHuman="$(humanDuration $estiTime)"
	fi
	local elapsedTimeHuman="$(humanDuration $elapsedTime)"
	
	# get length
	local beforeBar="$title $percentage% [" # bar之前的部分
	local afterBar="] $elapsedTimeHuman/$estiTimeHuman" # bar之后的部分
	local beforeBarLen=${#beforeBar}
	local afterBarLen=${#afterBar}
	
	# get bar
	local barMaxLen=$(($col-$beforeBarLen-$afterBarLen))
	local barMaxLen=$(( barMaxLen > 0 ? barMaxLen : 0 )) # 如果出现负值，说明窗口太窄了，就不画bar的部分了，只画头和尾
	local barLen=$(( barMaxLen < 40 ? barMaxLen : 40 )) # bar最大就给到40，如果屏幕很宽，bar也不会顶头
	local finishLen=$(echo "($barLen*$progress+0.5)/1" | bc)
	local leftLen=$(echo "($barLen*(1-$progress)+0.5)/1" | bc)
	local leftLen=$(( $finishLen+$leftLen > $barLen ? $(( leftLen-1 )) : leftLen )) # 上边两行四舍五入了，如果完成部分和剩余部分正好是0.5，就会出现都进位，从而多一个的情况，这时剩余部分-1
	local finish=$(head -c $finishLen /dev/zero |tr '\0' '=') # bar中的完成段
	local left=$(head -c $leftLen /dev/zero |tr '\0' ' ') # bar中的剩余段
	
	# print the bar
	local barLine="$beforeBar""$finish""$left""$afterBar"
	echo "$barLine"
	barLineLen=${#barLine}
}

# 按照array打印几个bars，不需要更新的直接打印，需要更新的再调用printBarLine
# 注意如果第一次传入的progress值为0，则startTime就设置为log时间；如果第一次不是0，startTime就是进程启动时间。
function printBarLineS() {
	local title=$1
	local progress=$2
	local index=0
	local found=0
	for titleEle in "${titleArray[@]}"
	do
	    if [[ "$title" == "$titleEle" ]] ; then
	        progressArray[$index]=progress
			found=1
	    fi
		printBarLine ${titleEle} ${progressArray[$index]} ${startTimeArray[$index]}
		index=$(($index+1))
		barLinesNo=$index
	done
	if [[ $found -eq 0 ]]; then
		titleArray[$index]="$title"
		progressArray[$index]=$progress
		if [[ $progress -eq 0 ]]; then
			startTimeArray[$index]=$SECONDS
		else
			startTimeArray[$index]=0
		fi
		printBarLine "${titleArray[$index]}" ${progressArray[$index]} ${startTimeArray[$index]}
		barLinesNo=$(($index+1))
	fi
}

# 当log不包含barPattern的时候，打印log，高亮或者过滤。
function printLog() {
	echo $1
}

# 当log包含DEBUG: task 0.2这样的Pattern时，不打印这句log，而是在最下边画一个进程条。
barPattern0d=".* DEBUG: \S+ 0\.[0-9]+$"
barPattern0=".* DEBUG: \S+ 0$"
barPattern1d=".* DEBUG: \S+ 1\.0+$"
barPattern1=".* DEBUG: \S+ 1$"
barLinesNo=0
barLineLen=0
titleArray=()
progressArray=()
startTimeArray=()

while ifs= read -r line
do
	if echo "$line" | egrep "$barPattern0d" >/dev/null || echo "$line" | egrep "$barPattern0" >/dev/null || echo "$line" | egrep "$barPattern1d" >/dev/null || echo "$line" | egrep "$barPattern1" >/dev/null; then
		returnFirstBarLine $barLinesNo $barLineLen
		#printBarLineS title 0.1
		printBarLine title 0.1 0
		barLinesNo=1
	else
		returnFirstBarLine $barLinesNo $barLineLen
		printLog "$line"
		printBarLine title 0.1 0
		barLinesNo=1
	fi
done < "${1:-/dev/stdin}"

