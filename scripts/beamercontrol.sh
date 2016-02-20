#!/bin/bash
logger $0 1=$1 2=$2
BEAMERIP=$(cat $(dirname "$0")"/beamerip.txt")
function raisescreen() {
  echo "Rolling projection screen up"
  ssh pi@doorbuzz 'doorbuzz/projectionscreen.sh up'
}
function lowerscreen() {
  echo "Rolling projection screen down"
  ssh pi@doorbuzz 'doorbuzz/projectionscreen.sh down'
}
function beameroff() {
  echo "Switching beamer off"
  wget -qO/dev/null http://$projip/tgi/return.tgi?command=2a3102fd0660 #projector off
}
function beameron() {
  echo "Switching beamer on"
  wget -qO/dev/null http://$projip/tgi/return.tgi?command=2a3101fe0660 #projector on
}
function dvi() {
  echo "Switching to dvi"
  wget -qO/dev/null http://$projip/tgi/return.tgi?command=2a3109f6070566 #switch to DVI
}
function hdmi1() {
  echo "Switching to hdmi1"
  wget -qO/dev/null http://$projip/tgi/return.tgi?command=2a3109f6071475 #switch to hdmi1
}
function hdmi2() {
  echo "Switching to hdmi2"
  wget -qO/dev/null http://$projip/tgi/return.tgi?command=2a3109f6071576 #switch to hdmi2
}
function vga1() {
  echo "Switching to vga1"
  wget -qO/dev/null http://$projip/tgi/return.tgi?command=2a3109f6070162 #switch to vga1
}
function vga2() {
  echo "Switching to vga2"
  wget -qO/dev/null http://$projip/tgi/return.tgi?command=2a3109f6070263 #switch to vga2
}
function usage() {
  echo "Usage: $0 (beamer|screen) (on|dvi|hdmi1|hdmi2|vga|off|down|up)"
  exit
}
projip="$(cat $(dirname "$0")"/beamerip.txt")"
case $1 in 
  beamer)
    case $2 in
      on) beameron
        ;;
      off) beameroff
        ;;
      dvi) beameron; dvi
        ;;
      hdmi1) beameron; hdmi1
        ;;
      hdmi2) beameron; hdmi2
        ;;
      vga1) beameron; vga1
        ;;
      *) usage
    esac
    ;;
  screen)
    case $2 in
      down|on) lowerscreen
      ;;
      up|off) raisescreen
      ;;
      *) usage
    esac
    ;;
  *)
    usage
    ;;
esac 
exit
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
  if [ "$signalsource" = "00" ] || [ "$signalsource" = "15" ] || [ "$signalsource" = "" ]
  then
    raisescreen
    echo "wget http://$projip/tgi/return.tgi?command=2a3102fd0660 #projector off"
    wget -qO - 'http://'"$projip"'/tgi/return.tgi?command=2a3102fd0660' 2>&1 
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
  statusbyte="$(wget -qO - 'http://'"$projip"'/tgi/return.tgi?query=info'|awk -F'[<>]' '/<info>/{print substr($3,31,2)}')"  
  if [ "$statusbyte" = "01" ]
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
  sleep 10
done
