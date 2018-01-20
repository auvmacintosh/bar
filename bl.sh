_barPattern0=".* DEBUG: \S+ 0\.[0-9]+$"
_barPattern1d=".* DEBUG: \S+ 1\.0+$"
_barPattern1=".* DEBUG: \S+ 1$"

_barLines=0
_barLen=60

__printBars() {
	local __barLines=$1
	local __barLen=$2
	for ((i=1;i<=$__barLines;i++))
	do
		__finish=`head -c $__barLen /dev/zero |tr '\0' '#'`
		echo $__finish
	done
}

__printLog() {
	echo $1
}

__findFirstBarLine() {
	local __barLines=$1
	local __barLen=$2
	local __col=$(tput cols)
	if [[ $__barLines -gt 0 ]]; then
		if [[ $__barLen -lt $__col ]] || [[ $__barLen -eq $__col ]]; then
			tput cuu $__barLines
		else
			tput cuu $(( $__barLines*2 ))
		fi
	fi
}

while ifs= read -r _line
do
	if `echo "$_line" | egrep "$_barPattern0" >/dev/null 2>&1` || `echo "$_line" | egrep "$_barPattern1d" >/dev/null 2>&1` || `echo "$_line" | egrep "$_barPattern1" >/dev/null 2>&1`; then
		__findFirstBarLine $_barLines $_barLen
		sleep 2
		_barLines=2
		__printBars $_barLines $_barLen
	else
		__findFirstBarLine $_barLines $_barLen
		sleep 2
		__printLog "$_line"
		_barLines=2
		__printBars $_barLines $_barLen
	fi
done < "${1:-/dev/stdin}"


