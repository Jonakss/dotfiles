#!/bin/bash}
height=25
dimensions="$(xrandr -q | grep -w Screen | cut -d " " -f 8)x$height+0+0"
barpid="$$"

# Colors and Fonts
urgent='#800000'
free='#50ffffff'
WHITE='#ffffff'
underline='#FA0012'

FONT1='-*-*-*-*-*-*-12-*-*-*-c-*-*-1'
FONT2='-wuncon-siji-medium-r-normal--10-100-75-75-c-80-iso10646-1'

# Check if panel is already running
if [ $(pgrep -cx lemonbar) -gt 0 ] ; then
	echo "%s\n" "La barra ya está iniciada" >&2
	exit 1
fi

# Stop processes on kill
trap 'trap - TERM; kill 0' INT TERM QUIT EXIT

# remove old panel fifo, create new one
fifo="/tmp/panel_fifo"
[ -e "$fifo" ] && rm "$fifo"
mkfifo "$fifo"

# Widgets

workspaces() {
	output=""
  WKS=10
	underline='#FA0012'

  for i in {2..6}
  do
    n=$(expr $i - 1)
    SPACE=$(bspc wm -g | cut -d ":" -f $i)
		case $SPACE in
			u*)
				output+=" %{A:bspc desktop -f ^$n:}%{F$urgent} ${SPACE:1} %{A}"
				;;
			O*)
				output+=" %{A:bspc desktop -f ^$n:}%{F$WHITE}%{U$underline+u} ${SPACE:1} %{-u}%{A}"
				;;
			U*)
				output+=" %{A:bspc desktop -f ^$n:}%{F$urgent}%{U$underline+u} ${SPACE:1} %{-u}%{A}"
				;;
			F*)
				output+=" %{A:bspc desktop -f ^$n:}%{F$free}%{U$underline+u} ${SPACE:1} %{-u}%{A}"
				;;
			o*)
				output+=" %{A:bspc desktop -f ^$n:}%{F$WHITE} ${SPACE:1} %{A}"
				;;
			*)
				output+=" %{A:bspc desktop -f ^$n:}%{F$free} ${SPACE:1} %{A}"
				;;
		esac
  done

  MODE=$(bspc wm -g | cut -d ":" -f $(expr $WKS + 2))
	case ${MODE:1} in
		M*)
			output+=" %{A:bspc desktop -l tiled:}%{F$free} ${MODE:1} %{A}"
			;;
		T*)
			output+=" %{A:bspc desktop -l monocle:}%{F$free} ${MODE:1} %{A}"
			;;
	esac
	echo -e "workspaces $output"
}

title(){
	title=$(xtitle)
	echo -e title$title
}

clock(){
	date="$(date "+%a %e %b %y %H:%M")"
	echo -e clock$date
}

battery(){
	capacity=$(cat /sys/class/power_supply/BAT0/capacity)
	if [ $(cat /sys/class/power_supply/ADP1/online) -eq 1 ]
	then
			icon_battery="\ue041"
			xbacklight -set 100
	else
			if [ $capacity -lt 80 ]
			then
				icon_battery="\ue032"
			elif [ $capacity -lt 50 ]
			then
				icon_battery="\ue031"
			elif [ $capacity -lt 25 ]
			then
				icon_battery="\ue030"
			else
				icon_battery="\ue033"
			fi
			xbacklight -set 60
	fi
	echo -e " battery$capacity%$icon_battery"
}

wifi(){
	signal=$(cat /proc/net/wireless | sed ':a;N;$!ba;s/\n/ /g' | cut -d " " -f 67 | cut -d "." -f 1)
	if [ "$signal" = "" ]
	then
		icon_wifi="\ue217"
	else
		if [ $signal -lt -80 ]
		then
			icon_wifi="\ue25d"
		elif [ $signal -lt -70 ]
		then
			icon_wifi="\ue25e"
		elif [ $signal -lt -60 ]
		then
			icon_wifi="\ue25f"
		elif [ $signal -lt -40 ]
		then
			icon_wifi="\ue260"
		else
			icon_wifi="\ue261"
		fi
	fi
	echo -e "wifi $icon_wifi"
}

volume(){
	headphones_mute=$(amixer sget Headphone | sed ':a;N;$!ba;s/\n/ /g' | cut -d "[" -f 4 | cut -d "]" -f 1)
	speakers_mute=$(amixer sget Speaker | sed ':a;N;$!ba;s/\n/ /g' | cut -d "[" -f 4 | cut -d "]" -f 1)
	volume=$(amixer sget Master | sed ':a;N;$!ba;s/\n/ /g' | cut -d "[" -f 2 | cut -d "%" -f 1)
	if [ $headphones_mute = "off" ]
	then
		volume_icon="\ue052"
		volume=0
	else
		if [ $volume -gt 50 ]
		then
			volume_icon="\ue05d"
		elif [ $volume -gt 25 ]
		then
			volume_icon="\ue053"
		else
			volume_icon="\ue051"
		fi
	fi
	echo -e "volume %{A:amixer sset Master toggle:}$volume%$volume_icon%{A}"
}

music(){
 echo "Musica"
}

# Ejecutar los Widgets en paralelo y enviar la salida al fifo
while :; do workspaces; sleep 0.4s; done > "$fifo" &
while :; do title; sleep 1s; done > "$fifo" &
while :; do clock; sleep 60s; done > "$fifo" &
while :; do battery; sleep 1s; done > "$fifo" &
while :; do wifi; sleep 30s; done > "$fifo" &
while :; do volume; sleep 1s; done > "$fifo" &
while :; do music; sleep 5s; done > "$fifo" &


while read -r line ; do
    case $line in
        workspaces*)
            workspaces="${line:10}"
            ;;
				title*)
						title="${line:5}"
						;;
				clock*)
						clock="${line:5}"
						;;
				battery*)
						battery="${line:7}"
						;;
				wifi*)
						wifi="${line:4}"
						;;
				volume*)
						volume="${line:6}"
						;;
				music*)
						music="${line:5}"
						;;
    esac
    echo -e "%{l}$workspaces %{F$WHITE}%{c}$title  %{r}$volume $wifi $battery  $clock \ue277 \ue277"
done < "$fifo" | lemonbar -f $FONT1 -f $FONT2 -u 2 -g $dimensions | bash; exit
