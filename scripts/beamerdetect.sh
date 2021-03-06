#!/bin/bash
BEAMERIP=$(cat $(dirname "$0")"/beamerip.txt")
function raisescreen() {
  echo "Rolling projection screen up"
  ssh pi@doorbuzz 'doorbuzz/projectionscreen.sh up'
  curl -X POST --header "Content-Type: text/plain" --header "Accept: application/json" -d "ON" "http://10.2.113.102:8080/rest/items/chill_zone_screen_button_up"
}
function pingall() {
  i=1
  while [ $i -lt 255 ]
  do
    ping -c 1 10.2.113.$i -q >/dev/null &
    i=$((i+1))
  done
  wait 
}
if [ "$1" = "off" ]
then
  (
  echo "called with parameter $1"
  projip="$BEAMERIP"
  if [ "$projip" = "" ]
  then
    echo "no projector IP found"
    arp -a 
    raisescreen
    exit
  fi
  signalsource="$(wget -qO - 'http://'"$projip"'/tgi/return.tgi?query=info' |awk -F'[<>]' '/<info>/{print substr($3,33,2)}')"
#  if [ "$signalsource" = "00" ] ||
#     [ "$signalsource" = "02" ] ||
#     [ "$signalsource" = "" ] ||
#     [ "$signalsource" = "15" ]     # always switch off if on chromecast # port 15 is hdmi1 (chromecast) 
  if true   # no more detecting if door closed by error. Nobody ever did that. Causes just issues
  then  
    raisescreen
    lightcommander projector dvioff # swith to slideshow and off
    lightcommander projector vol-
    echo "wget http://$projip/tgi/return.tgi?command=2a3102fd0660 #projector off"
    lightcommander projector off
    #wget -qO - 'http://'"$projip"'/tgi/return.tgi?command=2a3102fd0660' 2>&1 
    echo $? 
  else
    echo "not disabling projector because source is at $signalsource" 
  fi
  ) | logger -t "$(basename $0) $$"
  exit
fi &
if [ "$1" = "off" ]
then
  exit # because the if before is in background 
fi
prevstatus="unknown"
while true
do
  if [ $(date +%H) -eq 23 ]
  then
    pingall
  fi
  projip="$BEAMERIP"
  # from the acer webpage we read that bytes 30-31 contain 00 if power off and 01 if power on
  # we only test if 01, because if off, it can also give no response
  # but seems to be bytes 32-33 more accurate
  projectorstate="$(wget -qO - 'http://'"$projip"'/tgi/return.tgi?query=info'|awk -F'[<>]' '/<info>/{print substr($3,31,2)}')"  
  if [ "$projectorstate" = "01" ]
  then
    if [ "$prevstatus" != "on" ]
    then
      logger -t $(basename $0) "$$ Projector is on"
      ssh pi@doorbuzz 'doorbuzz/projectionscreen.sh down'
      prevstatus="on"
    fi
  else
    if [ "$prevstatus" != "off" ]
    then
      logger -t $(basename $0) "$$ Projector is off"
      prevstatus="off"
    fi
  fi
#  logger -t "$(basename $0) $$" "source=$signalsource cast=$(cat /var/run/caststatus)"
  sleep 10
  signalsource="$(wget -qO - 'http://'"$projip"'/tgi/return.tgi?query=info' |awk -F'[<>]' '/<info>/{print substr($3,33,2)}')"
  caststatus="$(cat /var/run/caststatus)"
  # bug: should only consider chromecast if beamer input is chromecast
#  logger "ss=$signalsource s=$(cat /root/var/spacestatus) c=$caststatus"
  if [ "$caststatus" != "Backdrop" ] && [ "$caststatus" != "None" ] && [ "$caststatus" != "" ] &&
     ( [ "$signalsource" = "" ] ||
       [ "$signalsource" = "00" ] ||
       [ "$signalsource" = "02" ] ) && 
     [ "$(cat /root/var/spacestatus)" = "open" ]
  then
    logger -t $(basename $0) "$$ signal on chromecast: $caststatus"
    logger -t $(basename $0) "$$ switching from $signalsource to hdmi2"
    lightcommander projector hdmi2
    sleep 3
  fi
done
