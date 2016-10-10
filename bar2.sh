#sudo iw dev wlp3s0 scan > networks_scanned
networks=($(cat networks_scanned | grep -w SSID | cut -d ":" -f 2 | cut -d " " -f 2))
signals=($(cat networks_scanned | grep -w signal | cut -d ":" -f 2 | cut -d " " -f 2 | cut -d "." -f 1))

output="Redes Disponibles \n"

for((i=0;i<${#networks[*]};i++)) do
	output+="^ca(1, exec:dzen2)"
	if [ ${signals[$i]} -lt -80 ]
	then
		output+="${networks[$i]} :...."
	elif [ ${signals[$i]} -lt -70 ]
	then
		output+="${networks[$i]} ::..."
	elif [ ${signals[$i]} -lt -60 ]
	then
		output+="${networks[$i]} :::.."
	elif [ ${signals[$i]} -lt -40 ]
	then
		output+="${networks[$i]} ::::."
	else
			output+="${networks[$i]} :::::"
	fi
	output+="^ca() \n"
done

echo -e $output | dzen2 -p 5 -x 200 -y 200 -w 200 -h 50 -l ${#networks[*]} -m v -e 'onstart=unhide,uncollapse; button3=exit;'
