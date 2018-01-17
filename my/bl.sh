while IFS= read -r line
do
	match=`echo "$line" | grep "0\."`
	echo "$match"
	if [ "$match" != null ]; then
		echo "$line"haha
	else
		echo "$line"
	fi
done < "${1:-/dev/stdin}"
