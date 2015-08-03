#!/bin/bash
if [ "$1" = "off" ]
then
  (
  echo "called with parameter $1"
  projip=$(arp -an|awk -F'[()]' '/00:50:41:79:d1:34/{print $2}')
  if [ "$projip" = "" ]
  then
    echo "no projector IP found"
    arp -a
    exit
  fi
  signalsource="$(wget -qO - 'http://'"$projip"'/tgi/return.tgi?query=info' |awk -F'[<>]' '/<info>/{print substr($3,33,2)}')"
  if [ "$signalsource" = "00" ] || [ "$signalsource" = "15" ] || [ "$signalsource" = "" ]
  then
    ssh pi@doorbuzz 'doorbuzz/projectionscreen.sh up'
    echo "wget http://$projip/tgi/return.tgi?command=2a3102fd0660 #projector off"
    wget -qO - 'http://'"$projip"'/tgi/return.tgi?command=2a3102fd0660' 2>&1 
    echo $? 
  else
    echo "not disabling projector because source is at $signalsource" 
  fi
  ) | logger -t "$(basename $0) $$"
  exit
fi
prevstatus="unknown"
while true
do
  projip=$(arp -an|awk -F'[()]' '/00:50:41:79:d1:34/{print $2}')
  # from the acer webpage we read that bytes 30-31 contain 00 if poer off and 01 if power on
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
