#!/bin/bash

function __returnFirstBarLine() {
	local __barLinesNo=$1
	if [[ $__barLinesNo -gt 0 ]]; then # 在至少已经打印了一行bar的情况下，才return
		local __barLineLen=$2
		local __col=$(tput cols)
		tput cuu `echo "$__barLinesNo*($__barLineLen+$__col-1)/$__col" | bc` # use bc to get ceil of divide/by:($divide+$by-1)/$by
		tput ed
	fi
}

function __humanTime {
	local __t=$1
	local __d=$((__t/60/60/24))
	local __h=$((__t/60/60%24))
	local __m=$((__t/60%60))
	local __s=$((__t%60))
	(( $__d > 0 )) && printf '%dd ' $__d
	(( $__d > 0 || $__h > 0 )) && printf '%02d:' $__h
	printf '%02d:' $__m
	printf '%02d' $__s
}

function __printBarLine() {
	# get input
	local __title="$1"
	local __progress=$2
	local __startTime=$3
	local __width=$(tput cols)

	# get readable information
	local __percentage=`echo "($__progress*100+0.5)/1" | bc` #/1是为了不保留小数（scale只对除法有用）。+0.5是四舍五入（bc默认去掉小数）。
	local __elapsedTime=$(($SECONDS - $__startTime))
	if [ $__progress == "0" ]; then
		local __estiTimeHuman="-" # 允许完成度为0，为了避免除0的情况发生，执行这个分支
	else
		local __estiTime=`echo "$__elapsedTime/$__progress" | bc` 
		local __estiTimeHuman=`__humanTime $__estiTime`
	fi
	local __elapsedTimeHuman=`__humanTime $__elapsedTime`
	
	# get length
	local __beforeBar="$__title $__percentage% [" # bar之前的部分
	local __afterBar="] $__elapsedTimeHuman/$__estiTimeHuman" # bar之后的部分
	local __beforeBarLen=`echo ${#__beforeBar}`
	local __afterBarLen=`echo ${#__afterBar}`
	
	# get bar
	local __barMaxLen=$(($__width-$__beforeBarLen-$__afterBarLen))
	local __barMaxLen=$(( __barMaxLen > 0 ? __barMaxLen : 0 )) # 如果出现负值，说明窗口太窄了，就不画bar的部分了，只画头和尾
	local __barLen=$(( __barMaxLen < 40 ? __barMaxLen : 40 )) # bar最大就给到40，如果屏幕很宽，bar也不会顶头
	local __finishLen=`echo "($__barLen*$__progress+0.5)/1" | bc`
	local __leftLen=`echo "($__barLen*(1-$__progress)+0.5)/1" | bc`
	local __leftLen=$(( $__finishLen+$__leftLen > $__barLen ? $(( __leftLen-1 )) : __leftLen )) # 上边两行四舍五入了，如果完成部分和剩余部分正好是0.5，就会出现都进位，从而多一个的情况，这时剩余部分-1
	local __finish=`head -c $__finishLen /dev/zero |tr '\0' '='` # bar中的完成段
	local __left=`head -c $__leftLen /dev/zero |tr '\0' ' '` # bar中的剩余段
	
	# print the bar
	local __barLine="$__beforeBar""$__finish""$__left""$__afterBar"
	echo "$__barLine"
	_barLineLen=`echo ${#__barLine}`
}

function __printLog() {
	echo $1
}

# 当log包含DEBUG: task 0.2这样的Pattern时，不打印这句log，而是在最下边画一个进程条。
# 注意如果第一次传入的progress值为0，则startTime就设置为log时间；如果第一次不是0，startTime就是进程启动时间。
# 当log不包含以上Pattern的时候，打印log，高亮或者过滤。

_barPattern0d=".* DEBUG: \S+ 0\.[0-9]+$"
_barPattern0=".* DEBUG: \S+ 0$"
_barPattern1d=".* DEBUG: \S+ 1\.0+$"
_barPattern1=".* DEBUG: \S+ 1$"
_barLinesNo=0
_barLineLen=0

while ifs= read -r _line
do
	if `echo "$_line" | egrep "$_barPattern0d" >/dev/null 2>&1` || `echo "$_line" | egrep "$_barPattern0" >/dev/null 2>&1` || `echo "$_line" | egrep "$_barPattern1d" >/dev/null 2>&1` || `echo "$_line" | egrep "$_barPattern1" >/dev/null 2>&1`; then
		__returnFirstBarLine $_barLinesNo $_barLineLen
		__printBarLine title 0.1 0
		_barLinesNo=1
	else
		__returnFirstBarLine $_barLinesNo $_barLineLen
		__printLog "$_line"
		__printBarLine title 0.1 0
		_barLinesNo=1
	fi
done < "${1:-/dev/stdin}"


