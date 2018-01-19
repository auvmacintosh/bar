bar() {
	echo $1
}

log() {
	echo $1
}

while ifs= read -r line
do
	case "$line" in
		*" 0."* ) #这块不行，最后会输出1
			bar "$line"
			;;
		* ) 
			log "$line"
			;;
	esac
done < "${1:-/dev/stdin}"


