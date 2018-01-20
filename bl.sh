barPattern0=".* DEBUG: \S+ 0\.[0-9]+$"
barPattern1d=".* DEBUG: \S+ 1\.0+$"
barPattern1=".* DEBUG: \S+ 1$"

bar() {
	echo $1haha
}

log() {
	echo $1
}

while ifs= read -r line
do
	if `echo "$line" | egrep "$barPattern0" >/dev/null 2>&1` || `echo "$line" | egrep "$barPattern1d" >/dev/null 2>&1` || `echo "$line" | egrep "$barPattern1" >/dev/null 2>&1`; then
		bar "$line"
	else
		log "$line"
	fi
done < "${1:-/dev/stdin}"


