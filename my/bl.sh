while IFS= read -r line
do
	#match=`echo "$line" | grep "0\."`
	#echo "$match"
	#if [ "$match" != null ]; then
	
	#if `echo "$line" | grep "0\." >/dev/null 2>&1`; then
	#	echo "$line"haha
	#else
	#	echo "$line"
	#fi
	case "$line" in
		*"0."* ) echo haha;;
		* ) echo "$line";;
	esac
done < "${1:-/dev/stdin}"
