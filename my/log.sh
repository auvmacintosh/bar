i=1
while true
	do
		echo "Task1 0.$((i%10))"
		i=$((i+1))
		sleep 1
		echo "DEBUG [main] AbstractBeanFactory.getBean(189) | Returning cached instance of singleton bean 'MyAutoProxy'"
	done

